package com.chen.football.common.dto;

public record MatchPredictionRequest(
    Long fixtureId,
    Long homeTeamId,
    Long awayTeamId,
    String homeTeamName,
    String awayTeamName,
    String leagueName,
    Integer leagueId
) {
    public MatchPredictionRequest(Long fixtureId, Long homeTeamId, Long awayTeamId) {
        this(fixtureId, homeTeamId, awayTeamId, null, null, null, null);
    }
}
