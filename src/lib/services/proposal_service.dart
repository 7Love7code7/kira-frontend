import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class ProposalService {
  final _storageService = getIt<StorageService>();
  List<Proposal> proposals = [];
  int totalCount = 0;
  int lastOffset = 0;

  Future<void> getProposalsCount() async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    var data = await http
        .get(apiUrl[0] + "/kira/gov/proposals?count_total=true", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    var bodyData = json.decode(data.body);
    if (!bodyData.containsKey('pagination')) return;

    totalCount = int.parse(bodyData['pagination']['total'] ?? '0');
  }

  Future<void> getProposals(bool loadNew, {String account = ''}) async {
    List<Proposal> proposalList = [];

    var apiUrl = await _storageService.getLiveRpcUrl();
    var offset, limit;
    if (loadNew) {
      offset = totalCount;
      await getProposalsCount();
      limit = totalCount - offset;
    } else {
      if (lastOffset == 0) {
        await getProposalsCount();
        lastOffset = totalCount;
      }
      offset = max(lastOffset - PAGE_COUNT, 0);
      limit = lastOffset - offset;
      lastOffset = offset;
    }
    if (limit == 0) return;

    var k = 0;
    while (k < limit) {
      if (!await _storageService.checkModelExists(ModelType.PROPOSAL, (offset + k).toString())) break;
      var proposal = Proposal.fromJson(await _storageService.getModel(ModelType.PROPOSAL, (offset + k).toString()));
      proposal.voteability = account.isEmpty ? Voteability.empty : await checkVoteability(proposal.proposalId, account);
      proposal.voteResults = await getVoteResult(proposal.proposalId);
      proposalList.add(proposal);
      k++;
    }

    if (k < limit) {
      var data = await http.get(
          apiUrl[0] + "/kira/gov/proposals?offset=${offset + k}&limit=${limit - k}&count_total=true",
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var bodyData = json.decode(data.body);
      if (!bodyData.containsKey('proposals')) return;

      var proposals = bodyData['proposals'];
      for (int i = 0; i < proposals.length; i++) {
        Proposal proposal = Proposal.fromJson(proposals[i]);
        proposal.voteability = await checkVoteability(proposal.proposalId, account);
        proposal.voteResults = await getVoteResult(proposal.proposalId);
        proposalList.add(proposal);
        _storageService.storeModels(ModelType.PROPOSAL, proposal.proposalId, proposal.jsonString);
      }
    }

    final now = DateTime.now();
    this.proposals.addAll(proposalList);
    var voteables = this.proposals.where((p) => p.votingEndTime.difference(now).inSeconds > 0).toList();
    var nonvoteables = this.proposals.where((p) => p.votingEndTime.difference(now).inSeconds <= 0).toList();
    voteables.sort((a, b) => b.votingEndTime.compareTo(a.votingEndTime));
    nonvoteables.sort((a, b) => b.enactmentEndTime.compareTo(a.enactmentEndTime));
    this.proposals.clear();
    this.proposals.addAll(voteables);
    this.proposals.addAll(nonvoteables);
  }

  Future<Voteability> checkVoteability(String proposalId, String account) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    var data =
        await http.get(apiUrl[0] + "/kira/gov/voters/$proposalId", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    var bodyData = json.decode(data.body);
    var actors = bodyData as List<dynamic>;
    var selfActor =
        actors.firstWhere((voter) => (voter as Map<String, dynamic>)['address'] == account, orElse: () => null);
    return parse(selfActor, actors.length);
  }

  Voteability parse(dynamic jsonData, int count) {
    List<VoteOption> options = [];
    if (jsonData == null) {
      return Voteability(voteOptions: [], whitelistPermissions: [], blacklistPermissions: [], count: count);
    }
    var data = jsonData as Map<String, dynamic>;
    if (data.containsKey("votes")) {
      (data['votes'] as List<dynamic>).forEach((item) {
        options.add(VoteOption.values[Strings.voteOptions.indexOf(item) + 1]);
      });
    }
    var whitelist = (jsonData['permissions']['whitelist'] as List<dynamic>).map((e) => e.toString()).toList();
    var blacklist = (jsonData['permissions']['blacklist'] as List<dynamic>).map((e) => e.toString()).toList();
    return Voteability(
        voteOptions: options, whitelistPermissions: whitelist, blacklistPermissions: blacklist, count: count);
  }

  Future<Map> getVoteResult(String proposalId) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    var data =
        await http.get(apiUrl[0] + "/kira/gov/votes/$proposalId", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    var bodyData = json.decode(data.body);
    var votes = bodyData as List<dynamic>;
    var counts = new Map<String, double>();
    votes.forEach((element) {
      var index = Strings.voteOptions.indexOf((element as Map<String, dynamic>)['option']) + 1;
      var optionKey = Strings.voteTitles[index];
      if (counts.keys.contains(optionKey))
        counts[optionKey]++;
      else
        counts[optionKey] = 1;
    });
    return counts;
  }
}
