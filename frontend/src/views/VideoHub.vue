<template>
  <div class="video-hub-page">
    <el-container>
      <el-header class="app-header">
        <div class="brand" @click="router.push('/matches')">
          <div class="brand-icon"><el-icon :size="22"><VideoCamera /></el-icon></div>
          <div>
            <div class="brand-title">足球视频中心</div>
            <div class="brand-subtitle">历史集锦 · 外部聚合 · 一键跳转观看</div>
          </div>
        </div>
        <el-menu mode="horizontal" :default-active="'3'" class="top-menu unified-menu" @select="handleMenuSelect">
          <el-menu-item index="0" class="menu-item"><el-icon><Calendar /></el-icon><span>比赛</span></el-menu-item>
          <el-menu-item index="1" class="menu-item"><el-icon><News /></el-icon><span>资讯</span></el-menu-item>
          <el-menu-item index="2" class="menu-item"><el-icon><User /></el-icon><span>我的</span></el-menu-item>
          <el-menu-item index="3" class="menu-item active"><el-icon><VideoCamera /></el-icon><span>视频</span></el-menu-item>
        </el-menu>
        <div class="header-actions">
          <el-button class="icon-btn" :icon="Refresh" circle @click="loadVideos" :loading="loading" />
          <el-dropdown @command="handleCommand">
            <el-avatar :size="36" class="header-avatar">{{ userStore.username?.[0]?.toUpperCase() }}</el-avatar>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile"><el-icon><User /></el-icon> 个人中心</el-dropdown-item>
                <el-dropdown-item command="history"><el-icon><Histogram /></el-icon> 预测历史</el-dropdown-item>
                <el-dropdown-item divided command="logout"><el-icon><SwitchButton /></el-icon> 退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <div class="hero-banner reveal video-hero">
          <div class="hero-copy">
            <div class="hero-tag">EXTERNAL VIDEO AGGREGATION</div>
            <h1>过往足球比赛视频聚合</h1>
            <p>收录历史比赛集锦、赛后回顾与精彩瞬间，点击卡片即可跳转到外部平台观看。</p>
          </div>
          <div class="hero-metrics">
            <div class="metric"><span>{{ videos.length }}</span><label>视频总数</label></div>
            <div class="metric"><span>{{ platformCount }}</span><label>平台来源</label></div>
            <div class="metric"><span>{{ filteredVideos.length }}</span><label>当前筛选</label></div>
          </div>
        </div>

        <div class="toolbar reveal">
          <el-input v-model="keyword" placeholder="搜索比赛、球队、联赛或平台" clearable class="search-input" @input="applyFilters">
            <template #prefix><el-icon><Search /></el-icon></template>
          </el-input>
          <el-select v-model="selectedPlatform" placeholder="全部平台" clearable class="filter-select" @change="applyFilters">
            <el-option label="全部平台" value="" />
            <el-option v-for="item in platformOptions" :key="item" :label="item" :value="item" />
          </el-select>
          <el-select v-model="selectedLeague" placeholder="全部联赛" clearable class="filter-select" @change="applyFilters">
            <el-option label="全部联赛" value="" />
            <el-option v-for="item in leagueOptions" :key="item" :label="item" :value="item" />
          </el-select>
          <el-select v-model="selectedType" placeholder="全部类型" clearable class="filter-select" @change="applyFilters">
            <el-option label="全部类型" value="" />
            <el-option v-for="item in typeOptions" :key="item" :label="item" :value="item" />
          </el-select>
        </div>

        <div v-if="loading" class="loading-state">
          <el-icon class="is-loading" :size="40"><Loading /></el-icon>
          <p>正在加载视频聚合数据...</p>
        </div>

        <div v-else-if="errorMsg" class="error-state">
          <el-icon :size="48" color="#F56C6C"><WarningFilled /></el-icon>
          <p>{{ errorMsg }}</p>
          <el-button type="primary" @click="loadVideos">重试</el-button>
        </div>

        <div v-else class="video-grid">
          <el-card v-for="video in filteredVideos" :key="video.id" class="video-card" shadow="never">
            <div class="thumb-wrap" @click="openVideo(video)">
              <img :src="video.cover" :alt="video.title" class="thumb" />
              <div class="play-badge"><el-icon><VideoPlay /></el-icon> 外部播放</div>
            </div>
            <div class="video-body">
              <div class="video-title">{{ video.title }}</div>
              <div class="video-meta">
                <el-tag size="small" type="info">{{ video.leagueName }}</el-tag>
                <el-tag size="small" type="success">{{ video.platform }}</el-tag>
                <el-tag size="small" type="warning">{{ video.videoType }}</el-tag>
              </div>
              <div class="video-desc">{{ video.description }}</div>
              <div class="video-footer">
                <span>{{ video.matchTime || '时间待定' }}</span>
                <el-button size="small" type="primary" @click="openVideo(video)">去观看</el-button>
              </div>
            </div>
          </el-card>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import api from '../api/index'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)
const errorMsg = ref('')
const keyword = ref('')
const selectedPlatform = ref('')
const selectedLeague = ref('')
const selectedType = ref('')
const videos = ref([])
const filteredVideos = ref([])

const platformOptions = computed(() => [...new Set(videos.value.map(v => v.platform).filter(Boolean))])
const leagueOptions = computed(() => [...new Set(videos.value.map(v => v.leagueName).filter(Boolean))])
const typeOptions = computed(() => [...new Set(videos.value.map(v => v.videoType).filter(Boolean))])
const platformCount = computed(() => platformOptions.value.length)

const normalizeVideo = (item) => ({
  id: item?.id,
  title: item?.title || '',
  subtitle: item?.subtitle || '',
  description: item?.description || '',
  cover: item?.coverImage || item?.cover || '',
  url: item?.videoUrl || item?.url || '',
  platform: item?.platform || '',
  leagueName: item?.leagueName || '',
  homeTeamName: item?.homeTeamName || '',
  awayTeamName: item?.awayTeamName || '',
  matchTime: item?.matchTime ? String(item.matchTime).slice(0, 10) : '',
  videoType: item?.videoType || '',
  isHot: item?.isHot || 0,
  isFeatured: item?.isFeatured || 0,
  sortOrder: item?.sortOrder || 0,
  status: item?.status || 'PUBLISHED'
})

const loadVideos = async () => {
  loading.value = true
  errorMsg.value = ''
  try {
    const res = await api.get('/videos', { params: { limit: 100 } })
    const items = res?.items || res?.data?.items || res?.data || []
    videos.value = Array.isArray(items) ? items.map(normalizeVideo) : []
    applyFilters()
  } catch (e) {
    errorMsg.value = '视频数据加载失败，请稍后再试'
    videos.value = []
    filteredVideos.value = []
  } finally {
    loading.value = false
  }
}

const applyFilters = () => {
  const kw = keyword.value.trim().toLowerCase()
  filteredVideos.value = videos.value.filter(video => {
    const matchKeyword = !kw || [video.title, video.subtitle, video.leagueName, video.platform, video.description, video.homeTeamName, video.awayTeamName].some(v => String(v).toLowerCase().includes(kw))
    const matchPlatform = !selectedPlatform.value || video.platform === selectedPlatform.value
    const matchLeague = !selectedLeague.value || video.leagueName === selectedLeague.value
    const matchType = !selectedType.value || video.videoType === selectedType.value
    return matchKeyword && matchPlatform && matchLeague && matchType && video.status === 'PUBLISHED'
  })
}

const openVideo = (video) => {
  if (!video?.url) return
  window.open(video.url, '_blank', 'noopener,noreferrer')
}

const handleMenuSelect = (index) => {
  if (index === '0') router.push('/matches')
  else if (index === '1') router.push('/news')
  else if (index === '2') router.push('/profile')
  else if (index === '3') return
}

const handleCommand = (cmd) => {
  if (cmd === 'logout') {
    userStore.logout()
    router.push('/login')
  } else if (cmd === 'profile') {
    router.push('/profile')
  } else if (cmd === 'history') {
    router.push('/profile?tab=history')
  }
}

onMounted(loadVideos)
</script>

<style scoped>
.video-hub-page {
  min-height: 100vh;
  background: linear-gradient(180deg, #f6f9ff 0%, #eef4ff 100%);
}
.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: rgba(255,255,255,0.9);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(64,158,255,0.12);
  position: sticky;
  top: 0;
  z-index: 20;
}
.brand { display:flex; align-items:center; gap:12px; cursor:pointer; }
.brand-icon {
  width: 42px; height: 42px; border-radius: 14px;
  background: linear-gradient(135deg, #409eff, #67c23a);
  color: #fff; display:flex; align-items:center; justify-content:center;
}
.brand-title { font-weight: 800; font-size: 18px; }
.brand-subtitle { color:#7a7a7a; font-size:12px; }
.main-content { max-width: 1280px; margin: 0 auto; width: 100%; padding: 24px; }
.hero-banner, .toolbar { background: rgba(255,255,255,0.9); border:1px solid rgba(64,158,255,0.12); border-radius: 20px; padding: 24px; box-shadow: 0 12px 30px rgba(64,158,255,0.08); }
.video-hero { display:flex; justify-content:space-between; gap:24px; align-items:stretch; }
.hero-copy h1 { margin: 10px 0; font-size: 34px; color: #15325b; }
.hero-copy p { color:#5f6b7a; max-width: 680px; line-height:1.7; }
.hero-tag { color:#409eff; font-weight:700; letter-spacing:1px; font-size:12px; }
.hero-metrics { display:grid; grid-template-columns:repeat(3, minmax(110px,1fr)); gap:12px; min-width: 320px; }
.metric { background: linear-gradient(180deg, #f8fbff, #edf5ff); border-radius:16px; padding:16px; text-align:center; }
.metric span { display:block; font-size:28px; font-weight:800; color:#1d4ed8; }
.metric label { font-size:12px; color:#6b7280; }
.toolbar { display:flex; gap:12px; margin-top:20px; flex-wrap:wrap; align-items:center; }
.search-input { flex: 1; min-width: 280px; }
.filter-select { width: 180px; }
.video-grid { margin-top:20px; display:grid; grid-template-columns:repeat(auto-fill, minmax(290px,1fr)); gap:18px; }
.video-card { border-radius: 18px; overflow:hidden; border:1px solid rgba(64,158,255,0.12); }
.thumb-wrap { position:relative; cursor:pointer; }
.thumb { width:100%; height:180px; object-fit:cover; display:block; }
.play-badge {
  position:absolute; left:12px; bottom:12px; background:rgba(10, 20, 40, 0.82);
  color:#fff; padding:8px 12px; border-radius:999px; display:flex; align-items:center; gap:6px; font-size:12px;
}
.video-body { padding:16px; }
.video-title { font-size:16px; font-weight:800; color:#1f2937; min-height: 48px; }
.video-meta { display:flex; gap:8px; margin:10px 0; flex-wrap:wrap; }
.video-desc { color:#6b7280; font-size:13px; line-height:1.6; min-height: 42px; }
.video-footer { display:flex; justify-content:space-between; align-items:center; margin-top:14px; color:#9ca3af; font-size:12px; }
.loading-state, .error-state { min-height: 280px; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#6b7280; gap:12px; }
@media (max-width: 900px) {
  .video-hero { flex-direction:column; }
  .hero-metrics { min-width: 0; grid-template-columns:repeat(3, 1fr); }
}
</style>
