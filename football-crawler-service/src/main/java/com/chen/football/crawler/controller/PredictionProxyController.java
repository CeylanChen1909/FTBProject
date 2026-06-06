package com.chen.football.crawler.controller;

import com.chen.football.common.dto.ApiResponse;
import com.chen.football.crawler.service.DeepSeekPredictionService;
import com.chen.football.crawler.service.ExternalPredictionProxyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/proxy")
@RequiredArgsConstructor
public class PredictionProxyController {

    private final ExternalPredictionProxyService proxyService;
    private final DeepSeekPredictionService deepSeekPredictionService;

    @GetMapping("/prediction")
    public ApiResponse<Map<String, Object>> predict(@RequestParam(name = "fixtureId", required = false) Long fixtureId,
                                                    @RequestParam(name = "homeTeam", required = false) String homeTeam,
                                                    @RequestParam(name = "awayTeam", required = false) String awayTeam,
                                                    @RequestParam(name = "leagueName", required = false) String leagueName) {
        Map<String, Object> base = proxyService.predict(fixtureId, homeTeam, awayTeam, leagueName);
        String prompt = String.format("请基于以下比赛给出足球预测JSON，只输出JSON对象，不要多余文本。要求字段：homeWinProb, drawProb, awayWinProb, resultLabel, tactical, basis, risk。比赛：fixtureId=%s, homeTeam=%s, awayTeam=%s, leagueName=%s。", fixtureId, homeTeam, awayTeam, leagueName);
        Map<String, Object> ai = deepSeekPredictionService.analyzeJson(prompt);
        Map<String, Object> merged = new LinkedHashMap<>(base);
        merged.put("ai", ai);
        merged.put("source", ai.getOrDefault("source", "proxy-heuristic-v2"));
        return ApiResponse.ok(merged);
    }

    @GetMapping("/h2h")
    public ApiResponse<Map<String, Object>> h2h(@RequestParam(name = "homeTeam") String homeTeam,
                                                @RequestParam(name = "awayTeam") String awayTeam,
                                                @RequestParam(name = "limit", defaultValue = "10") int limit) {
        Map<String, Object> base = proxyService.headToHead(homeTeam, awayTeam, limit);
        String prompt = String.format("请只输出一句简洁结论，格式为：XXX主队胜 / XXX平局 / XXX客队胜。球队：%s vs %s。", homeTeam, awayTeam);
        Map<String, Object> ai = deepSeekPredictionService.analyzeJson(prompt);
        Map<String, Object> merged = new LinkedHashMap<>(base);
        merged.put("ai", ai);
        return ApiResponse.ok(merged);
    }
}
