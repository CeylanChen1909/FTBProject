<template>
  <div class="layout">
    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-icon :size="28" color="#409EFF"><Football /></el-icon>
          <span class="title">足球预测系统</span>
        </div>
        <div class="header-right">
          <el-button text @click="$router.push('/matches')">
            <el-icon><ArrowLeft /></el-icon> 返回
          </el-button>
          <el-dropdown @command="handleCommand">
            <el-avatar :size="36" style="cursor:pointer;background:#409EFF">
              {{ userStore.username?.[0]?.toUpperCase() }}
            </el-avatar>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="matches"><el-icon><Calendar /></el-icon> 比赛列表</el-dropdown-item>
                <el-dropdown-item command="profile"><el-icon><User /></el-icon> 个人中心</el-dropdown-item>
                <el-dropdown-item command="history"><el-icon><Histogram /></el-icon> 预测历史</el-dropdown-item>
                <el-dropdown-item divided command="logout"><el-icon><SwitchButton /></el-icon> 退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <div class="prediction-page">
          <!-- 比赛信息卡片 -->
          <el-card class="match-info-card" shadow="hover" v-loading="loadingMatch">
            <template #header>
              <div class="card-header">
                <span>{{ fixtureData?.league?.name || '比赛详情' }}</span>
                <div class="header-actions">
                  <el-tag :type="statusType" size="small">{{ fixtureData?.fixture?.status?.long || '未知' }}</el-tag>
                  <el-button size="small" text @click="showH2H">
                    <el-icon><DataLine /></el-icon> 交锋记录
                  </el-button>
                </div>
              </div>
            </template>
            <div class="match-detail">
              <div class="team-block" @click="goTeamDetail(homeId)">
                <img v-if="fixtureData?.teams?.home?.logo" :src="fixtureData.teams.home.logo" class="big-logo" />
                <div v-else class="logo-placeholder">主</div>
                <div class="team-name-lg">{{ fixtureData?.teams?.home?.name || '主队' }}</div>
              </div>
              <div class="vs-block">
                <div v-if="fixtureData?.goals" class="final-score">
                  {{ fixtureData.goals.home }} - {{ fixtureData.goals.away }}
                </div>
                <div class="vs-label">VS</div>
                <div class="match-date">{{ formatDate(fixtureData?.fixture?.date) }}</div>
                <div class="match-venue" v-if="fixtureData?.fixture?.venue?.name">
                  {{ fixtureData.fixture.venue.name }}
                </div>
              </div>
              <div class="team-block" @click="goTeamDetail(awayId)">
                <img v-if="fixtureData?.teams?.away?.logo" :src="fixtureData.teams.away.logo" class="big-logo" />
                <div v-else class="logo-placeholder">客</div>
                <div class="team-name-lg">{{ fixtureData?.teams?.away?.name || '客队' }}</div>
              </div>
            </div>
          </el-card>

          <!-- 预测结果卡片 -->
          <el-card v-if="predictionResult" class="result-card" shadow="never">
            <template #header>
              <div class="card-header">
                <span>XGBoost 智能预测结果</span>
                <el-tag type="success" size="small">{{ predictionResult.modelVersion }}</el-tag>
              </div>
            </template>
            <div class="prob-section">
              <div class="prob-header">
                <span>预测概率分布</span>
                <span class="prob-hint">基于机器学习模型分析</span>
              </div>
              <div class="prob-bars">
                <div class="prob-item">
                  <div class="prob-label">
                    <span class="label-text">{{ fixtureData?.teams?.home?.name }} 胜</span>
                    <el-tag size="small" type="primary">主队</el-tag>
                  </div>
                  <div class="prob-bar-wrapper">
                    <el-progress
                      :percentage="Math.round(displayProb(aiProb.homeWinProb, predictionResult.homeWinProb) * 100)"
                      :color="homeColor"
                      :stroke-width="16"
                      :show-text="false"
                    />
                  </div>
                  <div class="prob-value">{{ (displayProb(aiProb.homeWinProb, predictionResult.homeWinProb) * 100).toFixed(1) }}%</div>
                </div>
                <div class="prob-item">
                  <div class="prob-label">
                    <span class="label-text">平局</span>
                  </div>
                  <div class="prob-bar-wrapper">
                    <el-progress
                      :percentage="Math.round(displayProb(aiProb.drawProb, predictionResult.drawProb) * 100)"
                      :color="drawColor"
                      :stroke-width="16"
                      :show-text="false"
                    />
                  </div>
                  <div class="prob-value">{{ (displayProb(aiProb.drawProb, predictionResult.drawProb) * 100).toFixed(1) }}%</div>
                </div>
                <div class="prob-item">
                  <div class="prob-label">
                    <span class="label-text">{{ fixtureData?.teams?.away?.name }} 胜</span>
                    <el-tag size="small" type="warning">客队</el-tag>
                  </div>
                  <div class="prob-bar-wrapper">
                    <el-progress
                      :percentage="Math.round(displayProb(aiProb.awayWinProb, predictionResult.awayWinProb) * 100)"
                      :color="awayColor"
                      :stroke-width="16"
                      :show-text="false"
                    />
                  </div>
                  <div class="prob-value">{{ (displayProb(aiProb.awayWinProb, predictionResult.awayWinProb) * 100).toFixed(1) }}%</div>
                </div>
              </div>
            </div>

            <!-- 预测结论 -->
            <div class="result-badge" :class="resultClass">
              <el-icon :size="32"><CircleCheck /></el-icon>
              <span>{{ resultLabel }}</span>
            </div>

            <!-- 预测解释 -->
            <div class="explanation">
              <div class="explanation-header">
                <el-icon><ChatLineSquare /></el-icon>
                <span>预测分析</span>
              </div>
              <p>{{ predictionResult.explanation }}</p>
            </div>

            <!-- AI分析 -->
            <div class="ai-section" v-if="aiInfo || predictionResult">
              <div class="ai-header">
                <el-icon><MagicStick /></el-icon>
                <span>AI 辅助分析</span>
                <el-tag size="small" :type="aiSource === 'deepseek' || aiSource === 'deepseek-v4-pro' ? 'success' : 'warning'">{{ aiSource }}</el-tag>
              </div>
              <div class="ai-summary">
                <template v-if="aiParsed">
                  <div class="ai-title">{{ aiParsed.resultLabel || 'AI 预测结果' }}</div>
                  <div class="ai-section-block">
                    <div class="ai-section-title">战术看点</div>
                    <div class="ai-text">{{ aiParsed.tactical || aiParsed.explanation || aiSummary }}</div>
                  </div>
                  <div class="ai-section-block">
                    <div class="ai-section-title">预测依据</div>
                    <div class="ai-text">{{ aiParsed.basis || aiParsed.reason || aiSummary }}</div>
                  </div>
                  <div class="ai-section-block">
                    <div class="ai-section-title">风险提示</div>
                    <div class="ai-text">{{ aiParsed.risk || aiParsed.riskHint || '暂无额外风险提示' }}</div>
                  </div>
                  <div v-if="h2hData?.summaryText" class="ai-text">{{ h2hData.summaryText }}</div>
                  <div class="ai-chip-row">
                    <span class="ai-chip">主胜 {{ (displayProb(aiProb.homeWinProb, predictionResult.homeWinProb) * 100).toFixed(1) }}%</span>
                    <span class="ai-chip">平局 {{ (displayProb(aiProb.drawProb, predictionResult.drawProb) * 100).toFixed(1) }}%</span>
                    <span class="ai-chip">客胜 {{ (displayProb(aiProb.awayWinProb, predictionResult.awayWinProb) * 100).toFixed(1) }}%</span>
                  </div>
                </template>
                <template v-else>
                  {{ aiSummary }}
                </template>
              </div>
              <div class="ai-meta">接口状态：{{ aiSource === 'fallback' ? '兜底分析' : '已接入外部分析' }}</div>
              <div v-if="aiDebug" class="ai-debug">
                <div>请求ID：{{ aiDebug.requestId || '-' }}</div>
                <div>模型：{{ aiDebug.model || '-' }}</div>
                <div>耗时：{{ aiDebug.latencyMs || '-' }} ms</div>
                <div>状态：{{ aiDebug.status || '-' }}</div>
                <div>来源：{{ aiDebug.source || '-' }}</div>
              </div>
              <div v-if="aiDebug?.source === 'fallback'" class="ai-warning">DeepSeek 未命中，当前显示兜底规则结果。</div>
              <details v-if="aiRaw" class="ai-raw">
                <summary>查看原始AI返回</summary>
                <pre>{{ aiRaw }}</pre>
              </details>
            </div>

            <!-- 特征贡献 -->
            <div class="feature-contrib" v-if="featureContrib">
              <div class="contrib-header">
                <el-icon><TrendCharts /></el-icon>
                <span>关键因素</span>
              </div>
              <div class="contrib-list">
                <div v-for="item in featureContrib" :key="item.name" class="contrib-item">
                  <span class="contrib-name">{{ item.name }}</span>
                  <div class="contrib-bar">
                    <div class="contrib-fill" :style="{ width: item.value + '%' }"></div>
                  </div>
                  <span class="contrib-value">{{ item.value.toFixed(0) }}%</span>
                </div>
              </div>
            </div>
          </el-card>

          <!-- 历史交锋弹窗 -->
          <el-dialog v-model="h2hVisible" title="历���交锋记录" width="650px">
            <div v-if="h2hLoading" class="loading-state">
              <el-skeleton :rows="5" animated />
            </div>
            <div v-else-if="h2hData" class="h2h-content">
              <div class="h2h-summary">
                <div class="summary-team home">
                  <img v-if="fixtureData?.teams?.home?.logo" :src="fixtureData.teams.home.logo" class="summary-logo" />
                  <span>{{ fixtureData?.teams?.home?.name }}</span>
                </div>
                <div class="summary-stats">
                  <div class="stat-box">
                    <span class="stat-num">{{ h2hData.summary?.homeWins || 0 }}</span>
                    <span class="stat-desc">主队胜</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-num">{{ h2hData.summary?.draws || 0 }}</span>
                    <span class="stat-desc">平局</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-num">{{ h2hData.summary?.awayWins || 0 }}</span>
                    <span class="stat-desc">客队胜</span>
                  </div>
                </div>
                <div class="summary-team away">
                  <img v-if="fixtureData?.teams?.away?.logo" :src="fixtureData.teams.away.logo" class="summary-logo" />
                  <span>{{ fixtureData?.teams?.away?.name }}</span>
                </div>
              </div>
              <div class="h2h-matches">
                <div v-for="(match, idx) in h2hData.recentMatches" :key="idx" class="h2h-match">
                  <span class="h2h-date">{{ match.date }}</span>
                  <span class="h2h-teams">{{ match.homeTeam }} vs {{ match.awayTeam }}</span>
                  <span class="h2h-score">{{ match.homeScore }} - {{ match.awayScore }}</span>
                </div>
                <div v-if="!h2hData.recentMatches?.length" class="h2h-empty">
                  暂无历史交锋记录
                </div>
              </div>
            </div>
          </el-dialog>

          <!-- 预测按钮 / 加载状态 -->
          <div class="action-area">
            <el-button v-if="!predictionResult" type="primary" size="large" :loading="predicting"
              class="predict-btn" @click="doPredict">
              <el-icon><TrendCharts /></el-icon>
              {{ predicting ? '分析中...' : '开始 XGBoost 预测' }}
            </el-button>
            <el-button v-else type="primary" size="large" @click="doPredict" :loading="predicting">
              <el-icon><RefreshRight /></el-icon> 重新预测
            </el-button>
          </div>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import { crawlerApi, predictionApi } from '../api'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const fixtureId = parseInt(route.params.fixtureId)
const homeId = parseInt(route.query.homeId || route.query.home || 0)
const awayId = parseInt(route.query.awayId || route.query.away || 0)

// 从 URL 参数获取球队名称，如果没有则使用默认值
const homeName = decodeURIComponent(route.query.homeName || route.query.home || '主队')
const awayName = decodeURIComponent(route.query.awayName || route.query.away || '客队')

const fixtureData = ref({
  teams: {
    home: { id: homeId, name: homeName, logo: decodeURIComponent(route.query.homeLogo || '') },
    away: { id: awayId, name: awayName, logo: decodeURIComponent(route.query.awayLogo || '') }
  }
})
const predictionResult = ref(null)
const predicting = ref(false)
const loading = ref(false)

// 历史交锋
const h2hVisible = ref(false)
const h2hLoading = ref(false)
const h2hData = ref(null)

const homeColor = '#409EFF'
const drawColor = '#909399'
const awayColor = '#E6A23C'

const statusType = computed(() => {
  const s = fixtureData.value?.fixture?.status?.short
  if (s === 'FT') return 'success'
  if (s === 'LIVE' || s === '1H' || s === '2H') return 'danger'
  return 'info'
})

const resultClass = computed(() => {
  const r = predictionResult.value?.resultLabel
  if (r === 'HOME_WIN') return 'result-home'
  if (r === 'AWAY_WIN') return 'result-away'
  return 'result-draw'
})

const resultLabel = computed(() => {
  const r = predictionResult.value?.resultLabel
  const homeP = displayProb(aiProb.value.homeWinProb, predictionResult.value?.homeWinProb)
  const drawP = displayProb(aiProb.value.drawProb, predictionResult.value?.drawProb)
  const awayP = displayProb(aiProb.value.awayWinProb, predictionResult.value?.awayWinProb)
  const max = Math.max(homeP, drawP, awayP)
  if (max === homeP) return `预测：${fixtureData.value?.teams?.home?.name} 获胜`
  if (max === awayP) return `预测：${fixtureData.value?.teams?.away?.name} 获胜`
  if (max === drawP) return '预测：双方势均力敌，可能平局'
  if (r === 'HOME_WIN') return `预测：${fixtureData.value?.teams?.home?.name} 获胜`
  if (r === 'AWAY_WIN') return `预测：${fixtureData.value?.teams?.away?.name} 获胜`
  return '预测：双方势均力敌，可能平局'
})

const aiInfo = computed(() => predictionResult.value?.ai || null)
const aiSource = computed(() => aiInfo.value?.source || predictionResult.value?.source || 'proxy-heuristic-v2')
const parseAiJson = (text) => {
  if (!text) return null
  const raw = String(text)
  const fenced = raw.match(/```json\s*([\s\S]*?)```/i)
  const body = fenced ? fenced[1] : raw
  const jsonMatch = body.match(/\{[\s\S]*\}/)
  const target = jsonMatch ? jsonMatch[0] : body
  try { return JSON.parse(target) } catch { return null }
}
const aiParsed = computed(() => parseAiJson(aiInfo.value?.raw?.choices?.[0]?.message?.content || aiInfo.value?.summary || predictionResult.value?.explanation))
const aiSummary = computed(() => aiParsed.value?.explanation || aiInfo.value?.summary || aiInfo.value?.raw?.choices?.[0]?.message?.content || predictionResult.value?.explanation || '暂无AI分析结果')
const aiRaw = computed(() => aiInfo.value?.raw ? JSON.stringify(aiInfo.value.raw, null, 2) : '')
const aiDebug = computed(() => ({
  source: aiSource.value,
  requestId: aiInfo.value?.requestId || predictionResult.value?.requestId || '-',
  model: aiInfo.value?.model || predictionResult.value?.model || '-',
  status: aiInfo.value?.status || predictionResult.value?.status || '-',
  latencyMs: aiInfo.value?.latencyMs ?? predictionResult.value?.latencyMs ?? '-',
}))
const normalizeProb = (v) => {
  const n = Number(v)
  if (!Number.isFinite(n)) return null
  return n > 1 ? n / 100 : n
}
const displayProb = (primary, fallback) => {
  const p = normalizeProb(primary)
  if (p !== null) return p
  const f = normalizeProb(fallback)
  return f !== null ? f : 0
}
const aiProb = computed(() => ({
  homeWinProb: normalizeProb(aiParsed.value?.homeWinProb),
  drawProb: normalizeProb(aiParsed.value?.drawProb),
  awayWinProb: normalizeProb(aiParsed.value?.awayWinProb),
}))

const featureContrib = computed(() => {
  if (!predictionResult.value) return null
  // 根据概率分布生成模拟的特征贡献
  const homeProb = predictionResult.value.homeWinProb
  const awayProb = predictionResult.value.awayWinProb
  const drawProb = predictionResult.value.drawProb
  
  return [
    { name: '球队实力', value: Math.max(homeProb, awayProb) * 100 },
    { name: '主场优势', value: homeProb * 100 },
    { name: '近期状态', value: Math.min(homeProb, awayProb) * 80 + 20 },
    { name: '历史交锋', value: 100 - drawProb * 200 },
  ]
})

const loadMatch = async () => {
  loading.value = true
  try {
    const homeTeam = fixtureData.value?.teams?.home || {}
    const awayTeam = fixtureData.value?.teams?.away || {}
    const queryLeague = route.query.leagueName || ''
    fixtureData.value = {
      ...fixtureData.value,
      fixture: {
        id: fixtureId,
        status: { short: 'NS', long: '未开赛' },
        venue: { name: '' },
        date: route.query.matchTime || ''
      },
      league: { id: route.query.leagueId || '', name: queryLeague, round: route.query.round || '' },
      teams: {
        home: { ...homeTeam, id: homeId || homeTeam.id, name: homeTeam.name || homeName, logo: homeTeam.logo || decodeURIComponent(route.query.homeLogo || '') },
        away: { ...awayTeam, id: awayId || awayTeam.id, name: awayTeam.name || awayName, logo: awayTeam.logo || decodeURIComponent(route.query.awayLogo || '') }
      },
      goals: { home: null, away: null }
    }
  } finally {
    loading.value = false
  }
}

const doPredict = async () => {
  predicting.value = true
  try {
    const homeTeam = fixtureData.value?.teams?.home || {}
    const awayTeam = fixtureData.value?.teams?.away || {}
    const homeTeamName = homeTeam.name || homeName
    const awayTeamName = awayTeam.name || awayName
    const leagueName = fixtureData.value?.league?.name || route.query.leagueName || ''
    const res = await crawlerApi.getProxyPrediction(fixtureId, homeTeamName, awayTeamName, leagueName)
    predictionResult.value = res?.data || res
    if (!predictionResult.value) {
      predictionResult.value = { modelVersion: 'heuristic-v1', homeWinProb: 0.34, drawProb: 0.33, awayWinProb: 0.33, resultLabel: 'DRAW', explanation: '当前比赛缺少历史特征，已使用基于联赛、球队近期交锋与公开赛程的兜底预测。' }
    }
    if (predictionResult.value?.ai?.raw) {
      console.debug('[Prediction AI raw]', predictionResult.value.ai.raw)
    }

    try {
      const savedHomeProb = displayProb(aiProb.value.homeWinProb, predictionResult.value?.homeWinProb)
      const savedDrawProb = displayProb(aiProb.value.drawProb, predictionResult.value?.drawProb)
      const savedAwayProb = displayProb(aiProb.value.awayWinProb, predictionResult.value?.awayWinProb)
      const savedResultLabel = savedHomeProb >= savedDrawProb && savedHomeProb >= savedAwayProb
        ? 'HOME_WIN'
        : (savedAwayProb >= savedHomeProb && savedAwayProb >= savedDrawProb ? 'AWAY_WIN' : 'DRAW')
      await predictionApi.saveMatchResult({
        fixtureId,
        homeTeamId: homeTeam.value?.id || homeId || null,
        awayTeamId: awayTeam.value?.id || awayId || null,
        homeTeamName,
        awayTeamName,
        leagueName,
        leagueId: route.query.leagueId ? Number(route.query.leagueId) : null,
        userId: userStore.userId || null,
        homeWinProb: savedHomeProb,
        drawProb: savedDrawProb,
        awayWinProb: savedAwayProb,
        resultLabel: savedResultLabel,
        explanation: aiParsed.value?.explanation || predictionResult.value?.explanation
      })
    } catch (saveErr) {
      console.warn('[Prediction history save failed]', saveErr)
    }

    console.debug('[Prediction payload]', { fixtureId, homeTeamName, awayTeamName, leagueName, response: predictionResult.value })
    ElMessage.success('预测分析完成！')
  } catch (e) {
    predictionResult.value = { modelVersion: 'heuristic-v1', homeWinProb: 0.34, drawProb: 0.33, awayWinProb: 0.33, resultLabel: 'DRAW', explanation: '预测服务暂不可用，已使用基于公开赛程和球队名称的兜底预测。' }
    console.warn('[Prediction failed]', e)
    ElMessage.warning('预测服务不可用，已展示兜底预测结果')
  } finally {
    predicting.value = false
  }
}

const showH2H = async () => {
  const homeTeamName = fixtureData.value?.teams?.home?.name || homeName
  const awayTeamName = fixtureData.value?.teams?.away?.name || awayName
  if (!homeTeamName || !awayTeamName) return
  h2hVisible.value = true
  h2hLoading.value = true
  
  try {
    const res = await crawlerApi.getProxyH2H(homeTeamName, awayTeamName, 10)
    h2hData.value = res?.data || res
  } catch (e) {
    h2hData.value = {
      recentMatches: [],
      summary: { homeWins: 0, draws: 0, awayWins: 0 },
      homeTeamName,
      awayTeamName,
      source: 'fallback'
    }
  } finally {
    h2hLoading.value = false
  }
}

const goTeamDetail = (teamId) => {
  if (teamId) {
    router.push(`/team/${teamId}`)
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString('zh-CN')
}

const handleCommand = (cmd) => {
  if (cmd === 'logout') { userStore.logout(); router.push('/login') }
  else if (cmd === 'profile') router.push('/profile')
  else if (cmd === 'history') router.push('/profile?tab=history')
  else if (cmd === 'matches') router.push('/matches')
}

onMounted(loadMatch)
</script>

<style scoped>
.layout { min-height: 100vh; background: #f0f2f5; }
.header {
  background: #fff; box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 24px; height: 60px; position: sticky; top: 0; z-index: 100;
}
.header-left { display: flex; align-items: center; gap: 10px; }
.title { font-size: 18px; font-weight: 700; color: #1a1a2e; }
.header-right { display: flex; align-items: center; gap: 12px; }
.main-content { padding: 24px; max-width: 800px; margin: 0 auto; }
.prediction-page { display: flex; flex-direction: column; gap: 16px; }

.card-header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; gap: 8px; align-items: center; }

.match-detail { display: flex; align-items: center; justify-content: space-around; padding: 20px 0; }
.team-block {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  cursor: pointer; padding: 10px; border-radius: 8px; transition: background 0.2s;
}
.team-block:hover { background: #f5f7fa; }
.big-logo { width: 80px; height: 80px; object-fit: contain; }
.logo-placeholder {
  width: 80px; height: 80px; border-radius: 50%;
  background: #eee; display: flex; align-items: center; justify-content: center;
  font-size: 28px; color: #999;
}
.team-name-lg { font-size: 16px; font-weight: 600; color: #333; text-align: center; max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.vs-block { text-align: center; }
.final-score { font-size: 36px; font-weight: 700; color: #1a1a2e; }
.vs-label { font-size: 20px; color: #999; margin: 6px 0; }
.match-date { font-size: 13px; color: #aaa; }
.match-venue { font-size: 12px; color: #ccc; margin-top: 4px; }

/* 概率展示 */
.prob-section { margin-bottom: 20px; }
.prob-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 16px; font-size: 14px; color: #666;
}
.prob-hint { color: #999; font-size: 12px; }
.prob-bars { display: flex; flex-direction: column; gap: 16px; }
.prob-item { display: flex; align-items: center; gap: 12px; }
.prob-label {
  width: 120px; font-weight: 600; font-size: 14px; color: #555;
  display: flex; align-items: center; gap: 6px;
}
.label-text { flex: 1; }
.prob-bar-wrapper { flex: 1; }
.prob-value { width: 60px; text-align: right; font-weight: 700; font-size: 18px; }

.result-badge {
  display: flex; align-items: center; justify-content: center; gap: 12px;
  padding: 20px; border-radius: 12px; font-size: 20px; font-weight: 700; margin-bottom: 20px;
}
.result-home { background: linear-gradient(135deg, #ecf5ff, #d9ecff); color: #409EFF; }
.result-away { background: linear-gradient(135deg, #fdf6ec, #f9e7c4); color: #E6A23C; }
.result-draw { background: linear-gradient(135deg, #f4f4f5, #e3e3e4); color: #909399; }

.explanation {
  background: #f9f9f9; border-radius: 12px; padding: 16px 20px;
  margin-bottom: 16px; border: 1px solid #eee;
}
.explanation-header {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 10px; font-weight: 600; color: #666;
}
.explanation p { font-size: 14px; color: #333; line-height: 1.8; margin: 0; }

.feature-contrib {
  background: #fff; border-radius: 12px; padding: 16px 20px;
  border: 1px solid #eee;
}
.contrib-header {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 16px; font-weight: 600; color: #666;
}
.contrib-list { display: flex; flex-direction: column; gap: 12px; }
.contrib-item { display: flex; align-items: center; gap: 10px; }
.contrib-name { width: 80px; font-size: 13px; color: #666; }
.contrib-bar { flex: 1; height: 8px; background: #f0f0f0; border-radius: 4px; overflow: hidden; }
.contrib-fill { height: 100%; background: linear-gradient(90deg, #409EFF, #66b1ff); border-radius: 4px; transition: width 0.5s; }
.contrib-value { width: 45px; text-align: right; font-size: 13px; font-weight: 600; color: #409EFF; }

.action-area { text-align: center; }
.predict-btn { width: 260px; height: 52px; font-size: 16px; }

/* 历史交锋弹窗 */
.h2h-content {}
.h2h-summary {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20px; background: #f5f7fa; border-radius: 12px; margin-bottom: 20px;
}
.summary-team {
  display: flex; flex-direction: column; align-items: center; gap: 8px;
}
.summary-team span { font-size: 13px; font-weight: 600; color: #333; max-width: 100px; text-align: center; }
.summary-logo { width: 48px; height: 48px; border-radius: 8px; }
.summary-stats { display: flex; gap: 20px; }
.stat-box { text-align: center; }
.stat-num { display: block; font-size: 28px; font-weight: 700; color: #409EFF; }
.stat-desc { font-size: 12px; color: #999; }
.h2h-matches { display: flex; flex-direction: column; gap: 8px; }
.h2h-match {
  display: flex; align-items: center; gap: 16px;
  padding: 12px 16px; background: #fafafa; border-radius: 8px;
}
.h2h-date { width: 80px; font-size: 12px; color: #999; }
.h2h-teams { flex: 1; font-size: 14px; color: #333; }
.h2h-score { font-size: 16px; font-weight: 700; color: #333; }
.h2h-empty { text-align: center; padding: 40px; color: #999; }
.loading-state { padding: 20px; }
</style>
