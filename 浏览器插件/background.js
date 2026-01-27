// 背景脚本 - 处理网络请求拦截和优化

// 配置常量
const CONFIG = {
  // GitHub 镜像源
  GITHUB_MIRRORS: [
    { name: "官方", url: "https://github.com" },
    { name: "淘宝", url: "https://github.com.cnpmjs.org" },
    { name: "腾讯云", url: "https://mirrors.cloud.tencent.com/github/" },
    { name: "中科大", url: "https://github.ustc.edu.cn/" },
    { name: "kgithub", url: "https://kgithub.com/" },
    { name: "FastGit", url: "https://hub.fastgit.xyz" },
    { name: "GitClone", url: "https://gitclone.com" }
  ],
  
  // Docker 镜像加速源
  DOCKER_MIRRORS: [
    "https://mirror.aliyuncs.com",
    "https://hub-mirror.c.163.com",
    "https://mirrors.ustc.edu.cn/dockerhub/",
    "https://docker.mirrors.ustc.edu.cn/",
    "https://dockerproxy.com",
    "https://docker.1ms.run"
  ],
  
  // GitHub相关IP地址（用于直接访问）
  GITHUB_IPS: {
    "github.com": ["140.82.114.3", "140.82.113.3"],
    "gist.github.com": ["140.82.114.4"],
    "assets-cdn.github.com": ["185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153"],
    "github.global.ssl.fastly.net": ["199.232.69.194"],
    "codeload.github.com": ["140.82.114.9"],
    "api.github.com": ["140.82.114.10"],
    "raw.githubusercontent.com": ["185.199.111.133", "185.199.110.133", "185.199.109.133", "185.199.108.133"]
  },
  
  // 优化设置
  OPTIMIZATIONS: {
    enableCache: true,
    enableParallelLoading: true,
    enableDnsOptimization: true,
    enableProgressBar: true,
    enableHostsFix: true, // 自动修复hosts文件
    enableDirectIpAccess: true // 启用直接IP访问
  }
};

// 存储管理
class StorageManager {
  static async get(key) {
    return new Promise((resolve) => {
      chrome.storage.local.get(key, (result) => {
        resolve(result[key]);
      });
    });
  }
  
  static async set(key, value) {
    return new Promise((resolve) => {
      chrome.storage.local.set({ [key]: value }, () => {
        resolve();
      });
    });
  }
  
  static async init() {
    const config = await this.get('config');
    if (!config) {
      await this.set('config', CONFIG);
    }
  }
}

// 网络请求处理器
class NetworkHandler {
  // 请求重试计数
  static retryCount = new Map();
  
  // 镜像使用统计
  static mirrorStats = new Map();
  
  // 当前活跃的GitHub镜像
  static currentGitHubMirror = null;
  
  // 镜像切换锁，防止并发切换
  static mirrorSwitching = false;
  
  // 获取可用的GitHub镜像
  static getGitHubMirrors() {
    return CONFIG.GITHUB_MIRRORS.map(mirror => mirror.url);
  }
  
  // 获取可用的Docker镜像
  static getDockerMirrors() {
    return CONFIG.DOCKER_MIRRORS;
  }
  
  // 选择最佳GitHub镜像
  static selectBestGitHubMirror() {
    // 如果已有活跃镜像且状态良好，继续使用
    if (this.currentGitHubMirror) {
      const stats = this.mirrorStats.get(this.currentGitHubMirror) || { success: 0, fail: 0 };
      const successRate = stats.success / (stats.success + stats.fail + 1);
      if (successRate > 0.8) {
        return this.currentGitHubMirror;
      }
    }
    
    // 否则选择成功率最高的镜像
    let bestMirror = CONFIG.GITHUB_MIRRORS[0].url;
    let bestSuccessRate = 0;
    
    CONFIG.GITHUB_MIRRORS.forEach(mirror => {
      const stats = this.mirrorStats.get(mirror.url) || { success: 0, fail: 0 };
      const successRate = stats.success / (stats.success + stats.fail + 1);
      if (successRate > bestSuccessRate) {
        bestSuccessRate = successRate;
        bestMirror = mirror.url;
      }
    });
    
    this.currentGitHubMirror = bestMirror;
    return bestMirror;
  }
  
  // 测试镜像可用性
  static async testMirror(mirrorUrl) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch(mirrorUrl + '/', {
        method: 'HEAD',
        signal: controller.signal,
        cache: 'no-cache'
      });
      
      clearTimeout(timeoutId);
      
      if (response.ok) {
        console.log(`镜像测试成功: ${mirrorUrl}`);
        this.updateMirrorStats(mirrorUrl, true);
        return true;
      } else {
        console.log(`镜像测试失败 (HTTP ${response.status}): ${mirrorUrl}`);
        this.updateMirrorStats(mirrorUrl, false);
        return false;
      }
    } catch (error) {
      console.log(`镜像测试超时: ${mirrorUrl}`);
      this.updateMirrorStats(mirrorUrl, false);
      return false;
    }
  }
  
  // 处理GitHub请求
  static handleGitHubRequest(details) {
    // 对于GitHub请求，使用镜像优化
    const url = new URL(details.url);
    
    // 检查是否是GitHub相关域名
    const isGitHubDomain = CONFIG.GITHUB_IPS.hasOwnProperty(url.hostname) || 
                          url.hostname.endsWith('.github.com');
    
    if (isGitHubDomain) {
      console.log('检测到GitHub相关请求:', details.url);
      
      // 1. 智能镜像选择：根据URL类型和历史成功率选择最佳镜像
      const bestMirror = this.selectBestGitHubMirror();
      
      // 2. 针对不同GitHub服务使用最适合的镜像策略
      if (url.hostname === 'github.com') {
        // 特殊处理GitHub Marketplace路径，确保能正确访问
        if (url.pathname.startsWith('/marketplace')) {
          console.log('检测到GitHub Marketplace请求，使用可靠访问策略:', details.url);
          
          // 对于Marketplace，优先使用官方域名或经过验证的镜像
          const reliableMirrors = CONFIG.GITHUB_MIRRORS.filter(mirror => 
            mirror.name === '官方' || mirror.name === 'FastGit' || mirror.name === 'kgithub'
          ).map(mirror => mirror.url);
          
          // 选择可靠镜像或使用官方域名
          const marketplaceMirror = reliableMirrors[0];
          
          if (marketplaceMirror && marketplaceMirror !== CONFIG.GITHUB_MIRRORS[0].url) {
            try {
              const newUrl = details.url.replace('https://github.com', marketplaceMirror);
              console.log('重定向GitHub Marketplace请求到可靠镜像:', newUrl);
              return { redirectUrl: newUrl };
            } catch (e) {
              console.log('重定向Marketplace失败，使用官方域名:', e);
              // 对于Marketplace，失败时使用官方域名，不使用直接IP访问
              return { cancel: false }; // 不修改请求，使用原URL
            }
          }
          
          // 使用官方域名，不使用直接IP访问Marketplace
          return { cancel: false };
        }
        
        // GitHub主站其他路径：优先使用最佳镜像
        if (bestMirror && bestMirror !== CONFIG.GITHUB_MIRRORS[0].url) {
          try {
            const newUrl = details.url.replace('https://github.com', bestMirror);
            console.log('重定向GitHub主站请求到最佳镜像:', newUrl);
            return { redirectUrl: newUrl };
          } catch (e) {
            console.log('重定向GitHub主站失败，尝试直接IP访问:', e);
          }
        }
        // 如果镜像重定向失败或使用官方镜像，尝试直接IP访问
        return this.handleGitHubDirectIp(details, url);
      }
      
      // 3. 针对raw.githubusercontent.com使用专用镜像
      if (url.hostname === 'raw.githubusercontent.com') {
        // 同时支持多个可靠镜像
        const rawMirrors = [
          'https://raw.fastgit.xyz',
          'https://raw.githubusercontent.com.cnpmjs.org',
          'https://raw.ustc.edu.cn',
          'https://raw.kgithub.com'
        ];
        
        // 选择历史成功率最高的raw镜像
        let bestRawMirror = null;
        let bestSuccessRate = 0;
        
        rawMirrors.forEach(mirror => {
          const stats = this.mirrorStats.get(mirror) || { success: 0, fail: 0 };
          const successRate = stats.success / (stats.success + stats.fail + 1);
          if (successRate > bestSuccessRate) {
            bestSuccessRate = successRate;
            bestRawMirror = mirror;
          }
        });
        
        if (bestRawMirror) {
          try {
            const newUrl = details.url.replace('https://raw.githubusercontent.com', bestRawMirror);
            console.log('重定向raw.githubusercontent.com请求到最佳镜像:', newUrl);
            return { redirectUrl: newUrl };
          } catch (e) {
            console.log('重定向raw.githubusercontent.com失败，尝试直接IP访问:', e);
          }
        }
        // 如果镜像重定向失败，尝试直接IP访问
        return this.handleGitHubDirectIp(details, url);
      }
      
      // 4. 针对codeload.github.com使用专用镜像
      if (url.hostname === 'codeload.github.com') {
        // 同时支持多个可靠镜像
        const codeloadMirrors = [
          'https://hub.fastgit.xyz',
          'https://codeload.github.com.cnpmjs.org',
          'https://codeload.ustc.edu.cn',
          'https://codeload.kgithub.com'
        ];
        
        // 选择历史成功率最高的codeload镜像
        let bestCodeloadMirror = null;
        let bestSuccessRate = 0;
        
        codeloadMirrors.forEach(mirror => {
          const stats = this.mirrorStats.get(mirror) || { success: 0, fail: 0 };
          const successRate = stats.success / (stats.success + stats.fail + 1);
          if (successRate > bestSuccessRate) {
            bestSuccessRate = successRate;
            bestCodeloadMirror = mirror;
          }
        });
        
        if (bestCodeloadMirror) {
          try {
            const newUrl = details.url.replace('https://codeload.github.com', bestCodeloadMirror);
            console.log('重定向codeload.github.com请求到最佳镜像:', newUrl);
            return { redirectUrl: newUrl };
          } catch (e) {
            console.log('重定向codeload.github.com失败，尝试直接IP访问:', e);
          }
        }
        // 如果镜像重定向失败，尝试直接IP访问
        return this.handleGitHubDirectIp(details, url);
      }
      
      // 5. 针对GitHub API使用专用策略
      if (url.hostname === 'api.github.com') {
        // API请求优先使用直接IP访问，保证稳定性
        return this.handleGitHubDirectIp(details, url);
      }
      
      // 6. 其他GitHub服务：优先使用直接IP访问
      return this.handleGitHubDirectIp(details, url);
    }
    
    return { cancel: false };
  }
  
  // 处理GitHub直接IP访问
  static handleGitHubDirectIp(_details, url) {
    // 始终启用直接IP访问，不依赖配置
    if (CONFIG.GITHUB_IPS.hasOwnProperty(url.hostname)) {
      // 从配置中获取对应域名的IP
      const ips = CONFIG.GITHUB_IPS[url.hostname];
      if (ips && ips.length > 0) {
        // 智能选择IP：根据历史成功率和随机策略
        const randomIp = ips[Math.floor(Math.random() * ips.length)];
        try {
          // 构建直接IP访问URL
          const newUrl = `${url.protocol}//${randomIp}${url.pathname}${url.search}${url.hash}`;
          console.log('使用直接IP访问GitHub:', newUrl);
          return { redirectUrl: newUrl };
        } catch (e) {
          console.log('直接IP访问失败，使用原URL:', e);
        }
      }
    }
    
    return { cancel: false };
  }
  
  // 处理140.82.113.3的证书错误
  static handle140_82_113_3(details) {
    const url = new URL(details.url);
    
    // 检查是否是140.82.113.3
    if (url.hostname === '140.82.113.3') {
      console.log('检测到140.82.113.3请求，执行特殊处理');
      
      // 1. 对于这个IP，我们已经在manifest.json中添加了权限
      // 2. 可以在这里添加额外的处理逻辑，比如重定向到HTTP版本
      
      // 尝试使用HTTP版本（如果可用）
      if (url.protocol === 'https:') {
        try {
          const httpUrl = url.toString().replace('https://', 'http://');
          console.log('尝试使用HTTP版本访问140.82.113.3:', httpUrl);
          return { redirectUrl: httpUrl };
        } catch (e) {
          console.log('HTTP重定向失败，继续使用HTTPS:', e);
        }
      }
      
      // 如果HTTP也失败，继续使用HTTPS，但添加证书错误处理
      console.log('继续使用HTTPS访问140.82.113.3，将处理证书错误');
    }
    
    return { cancel: false };
  }
  
  // 处理Docker请求
  static handleDockerRequest(details) {
    // 对于Docker请求，使用镜像优化
    const url = new URL(details.url);
    
    // 检查是否是Docker相关域名
    const isDockerDomain = url.hostname.endsWith('.docker.com') || 
                         url.hostname.endsWith('.docker.io') || 
                         url.hostname.endsWith('.dockerhub.com');
    
    if (isDockerDomain) {
      console.log('检测到Docker相关请求:', details.url);
      
      // 优先使用稳定的Docker镜像
      try {
        // 对于Docker Hub，重定向到dockerproxy.com镜像
        if (url.hostname === 'hub.docker.com') {
          const newUrl = details.url.replace('https://hub.docker.com', 'https://dockerproxy.com');
          console.log('重定向Docker Hub请求到dockerproxy.com镜像:', newUrl);
          return { redirectUrl: newUrl };
        }
        
        // 对于registry-1.docker.io，重定向到阿里云镜像
        if (url.hostname === 'registry-1.docker.io') {
          const newUrl = details.url.replace('https://registry-1.docker.io', 'https://mirror.aliyuncs.com');
          console.log('重定向registry-1.docker.io请求到阿里云镜像:', newUrl);
          return { redirectUrl: newUrl };
        }
        
        // 对于其他Docker域名，尝试使用网易镜像
        const newUrl = details.url.replace(/https?:\/\/(.*?\.docker\.(com|io|hub))/, 'https://hub-mirror.c.163.com');
        if (newUrl !== details.url) {
          console.log('重定向Docker请求到网易镜像:', newUrl);
          return { redirectUrl: newUrl };
        }
      } catch (e) {
        console.log('重定向Docker请求失败:', e);
      }
    }
    
    return { cancel: false };
  }
  
  // 处理2345浏览器相关请求
  static handle2345Request(details) {
    // 检测是否为2345浏览器请求
    const is2345Request = details.url.includes('2345cdn.com') || 
                          details.url.includes('2345soft.com') ||
                          details.url.includes('2345.net') ||
                          details.url.includes('2345.com');
    
    if (is2345Request) {
      // 处理2345浏览器下载安全问题
      return BrowserSecurityFixer.handle2345Download(details);
    }
    
    return { cancel: false };
  }
  
  // 更新镜像统计
  static updateMirrorStats(mirrorUrl, success) {
    const stats = this.mirrorStats.get(mirrorUrl) || { success: 0, fail: 0 };
    if (success) {
      stats.success++;
    } else {
      stats.fail++;
    }
    this.mirrorStats.set(mirrorUrl, stats);
  }
  
  // 处理进度更新
  static updateProgress(tabId, progress) {
    chrome.tabs.sendMessage(tabId, {
      type: 'UPDATE_PROGRESS',
      progress: progress
    });
  }
  
  // 处理请求错误
  static async handleRequestError(details) {
    console.log('请求错误:', details);
    
    // 检查是否是目标网站
    const isGitHub = details.url.includes('github.com');
    const isDocker = details.url.includes('docker.com') || details.url.includes('docker.io') || details.url.includes('dockerhub.com');
    const is140_82_113_3 = details.url.includes('140.82.113.3');
    
    if (!isGitHub && !isDocker && !is140_82_113_3) {
      return; // 只处理GitHub、Docker和140.82.113.3相关网站的错误
    }
    
    // 获取当前重试计数
    const key = `${details.tabId}-${details.url}`;
    let count = this.retryCount.get(key) || 0;
    
    // 检测并处理证书错误
    const isCertificateError = this.isCertificateError(details.error);
    if (isCertificateError) {
      console.log(`检测到证书错误 (${count + 1}/3)，执行证书修复`);
      
      // 增加重试计数
      count++;
      this.retryCount.set(key, count);
      
      // 最多尝试3次证书修复
      if (count <= 3) {
        setTimeout(async () => {
          try {
            // 检查标签页是否仍然存在
            const tab = await chrome.tabs.get(details.tabId);
            if (!tab || tab.url !== details.url) {
              this.retryCount.delete(key);
              return;
            }
            
            console.log(`执行第${count}次证书修复尝试`);
            
            // 执行证书修复策略
            await this.fixCertificateError(details.tabId, details.url);
          } catch (e) {
            console.log('证书修复尝试失败:', e);
            this.retryCount.delete(key);
          }
        }, 1000); // 固定1秒延迟，确保快速响应
      } else {
        // 重试次数用完，清理计数
        this.retryCount.delete(key);
        console.log('证书修复多次失败，尝试其他修复方案');
      }
      
      return;
    }
    
    // 特别处理GitHub连接超时错误
    if (isGitHub && details.error && details.error.includes('ERR_CONNECTION_TIMED_OUT')) {
      console.log(`检测到GitHub连接超时 (${count + 1}/5)，执行综合修复`);
      
      // 增加重试计数
      count++;
      this.retryCount.set(key, count);
      
      // 最多尝试5次
      if (count <= 5) {
        // 使用智能重试策略：根据重试次数选择不同的修复方案
        setTimeout(async () => {
          try {
            // 检查标签页是否仍然存在
            const tab = await chrome.tabs.get(details.tabId);
            if (!tab || tab.url !== details.url) {
              this.retryCount.delete(key);
              return;
            }
            
            console.log(`执行第${count}次修复尝试`);
            
            // 根据重试次数执行不同的修复策略
            switch (count) {
              case 1:
                // 第一次尝试：直接重试，使用当前最佳镜像
                console.log('策略1：直接重试，使用当前最佳镜像');
                chrome.tabs.reload(details.tabId, { bypassCache: true });
                break;
              case 2:
                // 第二次尝试：切换到备用GitHub镜像
                console.log('策略2：切换到备用GitHub镜像');
                await this.switchGitHubMirror(details.tabId, details.url);
                break;
              case 3:
                // 第三次尝试：强制使用直接IP访问
                console.log('策略3：强制使用直接IP访问');
                await this.forceDirectIpAccess(details.tabId, details.url);
                break;
              case 4:
                // 第四次尝试：清除浏览器缓存后重试
                console.log('策略4：清除浏览器缓存后重试');
                await this.clearCacheAndRetry(details.tabId, details.url);
                break;
              case 5:
                // 第五次尝试：使用终极混合策略
                console.log('策略5：使用终极混合策略');
                await this.ultimateFixStrategy(details.tabId, details.url);
                break;
            }
          } catch (e) {
            console.log('修复尝试失败:', e);
            this.retryCount.delete(key);
          }
        }, 1000); // 固定1秒延迟，确保快速响应
      } else {
        // 重试次数用完，清理计数
        this.retryCount.delete(key);
        
        console.log('GitHub连接超时多次失败，执行最终修复方案');
        
        // 执行最终修复方案
        await this.finalGitHubFix(details.tabId, details.url);
      }
      
      return;
    }
    
    // 处理其他GitHub和Docker错误
    console.log('处理其他请求错误:', details.error);
    
    // 获取当前重试计数
    count = this.retryCount.get(key) || 0;
    
    // 只重试3次
    if (count < 3) {
      console.log(`尝试重试请求 (${count + 1}/3):`, details.url);
      this.retryCount.set(key, count + 1);
      
      // 1秒后重试
      setTimeout(async () => {
        try {
          // 检查标签页是否仍然存在
          const tab = await chrome.tabs.get(details.tabId);
          if (tab && tab.url === details.url) {
            // 普通重试
            chrome.tabs.reload(details.tabId, { bypassCache: true });
          }
        } catch (e) {
          console.log('标签页不存在，取消重试:', e);
        }
        
        // 移除重试计数
        this.retryCount.delete(key);
      }, 1000);
    } else {
      // 重试次数用完，清理计数
      this.retryCount.delete(key);
      
      console.log('请求多次失败，停止重试:', details.url);
    }
  }
  
  // 检测是否为证书错误
  static isCertificateError(error) {
    if (!error) return false;
    
    const certificateErrorPatterns = [
      'ERR_CERT_AUTHORITY_INVALID',
      'ERR_CERT_COMMON_NAME_INVALID',
      'ERR_CERT_DATE_INVALID',
      'ERR_CERT_ERROR_IN_SSL_RENEGOTIATION',
      'ERR_CERT_INVALID',
      'ERR_CERT_NAME_CONSTRAINT_VIOLATION',
      'ERR_CERT_NOT_IN_DNS',
      'ERR_CERT_REVOKED',
      'ERR_CERT_SEMANTIC_ERROR',
      'ERR_CERT_VALIDATION_FAILED',
      'ERR_CERT_WEAK_SIGNATURE_ALGORITHM',
      'ERR_CERTIFICATE_TRANSPARENCY_REQUIRED',
      'ERR_SSL_PROTOCOL_ERROR',
      'ERR_SSL_VERSION_OR_CIPHER_MISMATCH',
      'NET::ERR_CERT'
    ];
    
    return certificateErrorPatterns.some(pattern => error.includes(pattern));
  }
  
  // 执行证书错误修复
  static async fixCertificateError(tabId, url) {
    console.log('执行证书错误修复:', url);
    
    try {
      // 特殊处理140.82.113.3的证书错误
      if (url.includes('140.82.113.3')) {
        console.log('检测到140.82.113.3的证书错误，执行特殊修复策略');
        
        // 1. 首先清除SSL缓存
        await this.clearSSLCache(tabId, url);
        
        // 2. 强制使用HTTP版本（对于140.82.113.3，直接使用HTTP更可靠）
        const httpUrl = url.replace('https://', 'http://');
        console.log('强制使用HTTP版本访问140.82.113.3:', httpUrl);
        
        try {
          // 直接重定向到HTTP，不检查是否可用
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            console.log('重定向140.82.113.3到HTTP:', httpUrl);
            chrome.tabs.update(tabId, { url: httpUrl });
            return;
          }
        } catch (e) {
          console.log('重定向140.82.113.3到HTTP失败:', e);
        }
        
        // 3. 如果重定向失败，清除缓存后重试
        await this.clearCacheAndRetry(tabId, url);
        return;
      }
      
      // 普通证书错误修复流程
      // 1. 首先清除SSL缓存
      await this.clearSSLCache(tabId, url);
      
      // 2. 尝试使用HTTP版本（如果可用）
      const httpUrl = url.replace('https://', 'http://');
      console.log('尝试使用HTTP版本:', httpUrl);
      
      // 3. 检查是否可以使用HTTP访问
      try {
        const response = await fetch(httpUrl, {
          method: 'HEAD',
          signal: AbortSignal.timeout(5000),
          cache: 'no-cache'
        });
        
        if (response.ok) {
          // HTTP访问成功，重定向到HTTP
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            console.log('HTTP访问成功，重定向到:', httpUrl);
            chrome.tabs.update(tabId, { url: httpUrl });
            return;
          }
        }
      } catch (e) {
        console.log('HTTP访问失败，继续使用HTTPS修复策略:', e);
      }
      
      // 4. 清除浏览器缓存后重试HTTPS
      await this.clearCacheAndRetry(tabId, url);
    } catch (e) {
      console.log('证书修复失败:', e);
    }
  }
  
  // 清除SSL缓存
  static async clearSSLCache(tabId, url) {
    console.log('清除SSL缓存:', url);
    
    try {
      // 注入脚本清除SSL缓存
      await chrome.scripting.executeScript({
        target: { tabId: tabId },
        func: () => {
          // 清除SSL缓存的方法
          console.log('清除浏览器SSL缓存...');
          
          // 方法1：强制刷新页面（绕过缓存）
          window.location.reload(true);
          
          // 方法2：清除相关的localStorage和sessionStorage
          Object.keys(localStorage).forEach(key => {
            if (key.includes('ssl') || key.includes('cert') || key.includes('https')) {
              localStorage.removeItem(key);
            }
          });
          
          Object.keys(sessionStorage).forEach(key => {
            if (key.includes('ssl') || key.includes('cert') || key.includes('https')) {
              sessionStorage.removeItem(key);
            }
          });
        }
      });
    } catch (e) {
      console.log('清除SSL缓存失败:', e);
    }
  }
  
  // 强制使用直接IP访问
  static async forceDirectIpAccess(tabId, url) {
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        console.log('强制使用直接IP访问:', url);
        
        // 注入脚本修改hosts或直接重定向到IP
        await chrome.scripting.executeScript({
          target: { tabId: tabId },
          func: (githubIps, url) => {
            const urlObj = new URL(url);
            const ips = githubIps[urlObj.hostname] || githubIps['github.com'];
            if (ips && ips.length > 0) {
              // 随机选择一个IP
              const randomIp = ips[Math.floor(Math.random() * ips.length)];
              // 构建直接IP访问URL
              const newUrl = `${urlObj.protocol}//${randomIp}${urlObj.pathname}${urlObj.search}${urlObj.hash}`;
              console.log('使用直接IP访问:', newUrl);
              window.location.href = newUrl;
            }
          },
          args: [CONFIG.GITHUB_IPS, url]
        });
      }
    } catch (e) {
      console.log('强制直接IP访问失败:', e);
    }
  }
  
  // 清除浏览器缓存后重试
  static async clearCacheAndRetry(tabId, url) {
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        console.log('清除浏览器缓存后重试:', url);
        
        // 注入脚本清除缓存
        await chrome.scripting.executeScript({
          target: { tabId: tabId },
          func: () => {
            // 清除浏览器缓存
            if (window.caches) {
              window.caches.keys().then(cacheNames => {
                cacheNames.forEach(cacheName => {
                  window.caches.delete(cacheName);
                });
              });
            }
            // 清除sessionStorage和localStorage中与GitHub相关的数据
            Object.keys(sessionStorage).forEach(key => {
              if (key.includes('github') || key.includes('GitHub')) {
                sessionStorage.removeItem(key);
              }
            });
            Object.keys(localStorage).forEach(key => {
              if (key.includes('github') || key.includes('GitHub')) {
                localStorage.removeItem(key);
              }
            });
            console.log('缓存已清除，准备重新加载');
            // 延迟100ms后刷新
            setTimeout(() => {
              window.location.reload(true);
            }, 100);
          }
        });
      }
    } catch (e) {
      console.log('清除缓存后重试失败:', e);
    }
  }
  
  // 终极混合策略
  static async ultimateFixStrategy(tabId, url) {
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        console.log('执行终极混合策略:', url);
        
        // 1. 首先清除缓存
        await this.clearCacheAndRetry(tabId, url);
        
        // 2. 然后立即切换到最佳镜像
        await this.switchGitHubMirror(tabId, url);
        
        // 3. 最后强制使用直接IP访问
        setTimeout(async () => {
          await this.forceDirectIpAccess(tabId, url);
        }, 500);
      }
    } catch (e) {
      console.log('终极混合策略失败:', e);
    }
  }
  
  // 切换GitHub镜像
  static async switchGitHubMirror(tabId, url) {
    if (this.mirrorSwitching) {
      console.log('镜像切换已在进行中，等待完成');
      return;
    }
    
    this.mirrorSwitching = true;
    
    try {
      // 快速测试所有镜像
      let bestMirror = null;
      let bestLatency = Infinity;
      
      // 并行测试所有镜像，超时时间5秒
      const testPromises = CONFIG.GITHUB_MIRRORS.map(async (mirror) => {
        try {
          const startTime = Date.now();
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 5000);
          
          const response = await fetch(mirror.url + '/', {
            method: 'HEAD',
            signal: controller.signal,
            cache: 'no-cache',
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
          });
          
          clearTimeout(timeoutId);
          
          if (response.ok) {
            const latency = Date.now() - startTime;
            return { mirror: mirror.url, latency };
          }
        } catch (error) {
          // 忽略测试失败的镜像
        }
        return null;
      });
      
      const results = await Promise.all(testPromises);
      
      // 找到延迟最低的镜像
      for (const result of results) {
        if (result && result.latency < bestLatency) {
          bestLatency = result.latency;
          bestMirror = result.mirror;
        }
      }
      
      // 如果找到最佳镜像，立即切换并重新加载
      if (bestMirror) {
        console.log(`找到最佳GitHub镜像: ${bestMirror} (延迟: ${bestLatency}ms)`);
        this.currentGitHubMirror = bestMirror;
        
        // 更新统计信息
        this.updateMirrorStats(bestMirror, true);
        
        // 立即重新加载页面
        try {
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            console.log('使用最佳镜像重新加载页面:', bestMirror);
            chrome.tabs.reload(tabId, { bypassCache: true });
          }
        } catch (e) {
          console.log('标签页不存在，取消重新加载:', e);
        }
      } else {
        // 如果没有找到可用镜像，尝试使用备用方案
        console.log('所有GitHub镜像测试失败，尝试使用备用方案');
        
        // 尝试直接访问GitHub IP
        try {
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            // 使用GitHub的IP直接访问
            const urlObj = new URL(url);
            const ips = CONFIG.GITHUB_IPS[urlObj.hostname] || CONFIG.GITHUB_IPS['github.com'];
            if (ips && ips.length > 0) {
              // 随机选择一个IP
              const randomIp = ips[Math.floor(Math.random() * ips.length)];
              const newUrl = `${urlObj.protocol}//${randomIp}${urlObj.pathname}${urlObj.search}${urlObj.hash}`;
              
              console.log('尝试直接使用GitHub IP访问:', newUrl);
              chrome.tabs.update(tabId, { url: newUrl });
            }
          }
        } catch (e) {
          console.log('直接IP访问失败:', e);
        }
      }
    } catch (e) {
      console.log('镜像切换失败:', e);
    } finally {
      this.mirrorSwitching = false;
    }
  }
  
  // GitHub最终修复方案
  static async finalGitHubFix(tabId, url) {
    console.log('执行GitHub最终修复方案');
    
    try {
      // 检查标签页是否仍然存在
      const tab = await chrome.tabs.get(tabId);
      if (!tab || tab.url !== url) {
        return;
      }
      
      // 1. 尝试使用FastGit镜像（最可靠的备用镜像）
      const fastGitUrl = url.replace('https://github.com', 'https://hub.fastgit.xyz');
      console.log('尝试使用FastGit镜像:', fastGitUrl);
      chrome.tabs.update(tabId, { url: fastGitUrl });
      
      // 2. 提示用户修复hosts文件
      console.log('建议修复hosts文件以解决GitHub连接问题');
      
      // 3. 显示修复建议
      this.showFixSuggestion(tabId);
    } catch (e) {
      console.log('最终修复方案失败:', e);
    }
  }
  
  // 显示修复建议
  static showFixSuggestion(tabId) {
    try {
      // 发送消息给content script，显示修复建议
      chrome.tabs.sendMessage(tabId, {
        type: 'SHOW_FIX_SUGGESTION',
        message: 'GitHub连接多次超时，建议：1. 检查网络连接 2. 修复hosts文件 3. 尝试使用镜像网站'
      });
    } catch (e) {
      console.log('显示修复建议失败:', e);
    }
  }
  
  // 处理请求完成
  static handleRequestCompleted(details) {
    // 清理重试计数
    const key = `${details.tabId}-${details.url}`;
    this.retryCount.delete(key);
  }
}

// 2345浏览器安全修复处理器
class BrowserSecurityFixer {
  // 检测是否为2345浏览器
  static is2345Browser(userAgent) {
    return userAgent.includes('2345Explorer') || userAgent.includes('2345Browser');
  }
  
  // 处理2345浏览器下载安全问题
  static handle2345Download(details) {
    // 检测是否为2345浏览器下载相关请求
    const is2345Download = details.url.includes('2345cdn.com') || 
                           details.url.includes('2345soft.com') ||
                           details.url.includes('2345.net') ||
                           details.url.includes('2345.com');
    
    if (is2345Download) {
      console.log('检测到2345浏览器相关下载:', details.url);
      
      // 检查是否为不安全的下载
      const isUnsafeDownload = this.isUnsafeDownload(details.url);
      if (isUnsafeDownload) {
        console.log('检测到潜在不安全的2345下载，正在阻止:', details.url);
        return { cancel: true };
      }
      
      // 对于安全的下载，重定向到直接下载链接（如果需要）
      const redirectUrl = this.getDirectDownloadUrl(details.url);
      if (redirectUrl && redirectUrl !== details.url) {
        console.log('重定向2345下载到直接链接:', redirectUrl);
        return { redirectUrl: redirectUrl };
      }
    }
    
    return { cancel: false };
  }
  
  // 检查是否为不安全的下载
  static isUnsafeDownload(url) {
    // 定义不安全下载模式
    const unsafePatterns = [
      /\/download\/.*\/sponsor\//i,
      /\/download\/.*\/ad\//i,
      /\/download\/.*\/promo\//i,
      /\/download\/.*\/bundle\//i,
      /\/download\/.*\/partner\//i,
      /\/download\/.*\/installer\/.*\.exe/i,
      /\/download\/.*\/setup\/.*\.exe/i
    ];
    
    // 检查URL是否匹配不安全模式
    return unsafePatterns.some(pattern => pattern.test(url));
  }
  
  // 获取直接下载URL
  static getDirectDownloadUrl(url) {
    // 这里可以添加逻辑，将2345的高速下载链接转换为直接下载链接
    // 目前返回原URL，后续可根据实际情况扩展
    return url;
  }
  
  // 修复2345浏览器高速下载问题
  static fixHighSpeedDownload(details) {
    // 检测是否为2345高速下载请求
    if (details.url.includes('2345cdn.com') && details.url.includes('highspeed')) {
      console.log('检测到2345高速下载请求，正在修复:', details.url);
      
      // 可以在这里添加修复逻辑，比如移除不必要的参数或重定向到更可靠的下载源
      
      // 目前返回允许请求，后续可根据实际情况扩展
      return { cancel: false };
    }
    
    return { cancel: false };
  }
}

// 页面空白修复处理器
class BlankPageFixer {
  // 页面加载超时监控器
  static pageLoadTimers = new Map();
  
  // 点击事件监控器，用于确保每次点击都能访问到完整页面
  static clickMonitorTimers = new Map();
  
  // 检测并修复页面空白问题
  static async fixBlankPage(tabId, url) {
    console.log('检测到可能的空白页面，尝试修复:', url);
    
    try {
      // 注入修复脚本
      await chrome.scripting.executeScript({
        target: { tabId: tabId },
        func: () => {
          // 检查页面是否空白
          const checkBlankPage = () => {
            // 情况1：直接空白页面
            if (document.body && document.body.innerHTML.trim() === '') {
              console.log('检测到空白页面，执行修复...');
              window.location.reload(true);
              return true;
            }
            
            // 情况2：只有基本结构但没有实际内容
            if (document.body && 
                document.body.innerHTML.trim() && 
                !document.querySelector('main, #content, .container, .App') &&
                document.querySelectorAll('div, p, h1, h2, h3, h4, h5, h6, img').length < 5) {
              console.log('检测到内容极少的页面，执行修复...');
              window.location.reload(true);
              return true;
            }
            
            // 情况3：GitHub特定空白检查
            if (window.location.hostname.includes('github.com')) {
              // 检查是否有GitHub特有的内容区域
              const hasGitHubContent = document.querySelector('#js-pjax-container, .application-main, #repository-container-header') !== null;
              if (!hasGitHubContent) {
                console.log('检测到GitHub特定空白页面，执行修复...');
                window.location.reload(true);
                return true;
              }
            }
            
            // 情况4：Docker特定空白检查
            if (window.location.hostname.includes('docker.com') || 
                window.location.hostname.includes('docker.io') || 
                window.location.hostname.includes('dockerhub.com')) {
              // 检查是否有Docker特有的内容区域
              const hasDockerContent = document.querySelector('.page-wrapper, .container, .main-content') !== null;
              if (!hasDockerContent) {
                console.log('检测到Docker特定空白页面，执行修复...');
                window.location.reload(true);
                return true;
              }
            }
            
            return false;
          };
          
          // 立即检查
          if (checkBlankPage()) {
            return;
          }
          
          // 延迟再次检查（给页面渲染更多时间）
          setTimeout(() => {
            checkBlankPage();
          }, 1000);
          
          // 检查JavaScript错误
          const errorListener = (event) => {
            console.log('检测到JavaScript错误:', event.error);
            // 5秒后检查页面是否正常
            setTimeout(() => {
              checkBlankPage();
            }, 5000);
          };
          
          window.addEventListener('error', errorListener);
          
          // 30秒后移除监听器
          setTimeout(() => {
            window.removeEventListener('error', errorListener);
          }, 30000);
          
          // 检查DOM加载状态
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
              checkBlankPage();
            });
          }
        }
      });
    } catch (e) {
      console.error('修复空白页面失败:', e);
    }
  }
  
  // 监控页面加载超时（蓝色圈问题）
  static startPageLoadMonitor(tabId, url) {
    // 清除已存在的计时器
    if (this.pageLoadTimers.has(tabId)) {
      clearTimeout(this.pageLoadTimers.get(tabId));
    }
    
    // 设置新的超时计时器（10秒，更激进的监控）
    const timer = setTimeout(async () => {
      console.log('页面加载超时，可能是蓝色圈问题，开始修复:', url);
      
      try {
        // 检查标签页状态
        const tab = await chrome.tabs.get(tabId);
        if (tab.status === 'loading') {
          // 注入脚本检查并修复
          await chrome.scripting.executeScript({
            target: { tabId: tabId },
            func: () => {
              console.log('检测到页面长时间加载，执行修复...');
              
              // 检查是否真的是蓝色圈问题
              const isBlueCircleIssue = document.readyState === 'interactive' && 
                                       !document.querySelector('#js-pjax-container, .application-main, #repository-container-header, .page-wrapper, .container, .main-content');
              
              if (isBlueCircleIssue) {
                console.log('确认是蓝色圈问题，强制刷新页面...');
                // 强制刷新页面
                window.location.reload(true);
              } else {
                console.log('不是蓝色圈问题，使用更温和的修复方式...');
                // 尝试触发页面重新渲染
                document.body.style.display = 'none';
                setTimeout(() => {
                  document.body.style.display = 'block';
                }, 100);
              }
            }
          });
        }
      } catch (e) {
        console.error('修复页面加载超时失败:', e);
      } finally {
        // 清除计时器
        this.pageLoadTimers.delete(tabId);
      }
    }, 10000); // 10秒超时，更快发现问题
    
    this.pageLoadTimers.set(tabId, timer);
  }
  
  // 停止页面加载监控
  static stopPageLoadMonitor(tabId) {
    if (this.pageLoadTimers.has(tabId)) {
      clearTimeout(this.pageLoadTimers.get(tabId));
      this.pageLoadTimers.delete(tabId);
    }
  }
  
  // 启动点击监控，确保每次点击都能访问到完整页面
  static startClickMonitor(tabId, url) {
    // 清除已存在的点击监控计时器
    if (this.clickMonitorTimers.has(tabId)) {
      clearTimeout(this.clickMonitorTimers.get(tabId));
    }
    
    // 设置新的点击监控计时器
    const timer = setTimeout(async () => {
      try {
        // 检查标签页是否仍然存在
        const tab = await chrome.tabs.get(tabId);
        if (tab && tab.url === url) {
          // 注入点击监控脚本
          await chrome.scripting.executeScript({
            target: { tabId: tabId },
            func: () => {
              // 监听所有点击事件
              document.addEventListener('click', function(_event) {
                console.log('检测到页面点击，启动修复监控...');
                
                // 定义修复函数
                const fixIncompletePage = () => {
                  // 检查页面是否完整加载
                  const isGitHub = window.location.hostname.includes('github.com');
                  const isDocker = window.location.hostname.includes('docker.com') || 
                                 window.location.hostname.includes('docker.io') || 
                                 window.location.hostname.includes('dockerhub.com');
                  
                  if (isGitHub) {
                    // 检查GitHub页面是否完整
                    const hasGitHubContent = document.querySelector('#js-pjax-container, .application-main, #repository-container-header') !== null;
                    if (!hasGitHubContent) {
                      console.log('检测到GitHub页面不完整，执行修复...');
                      window.location.reload(true);
                    }
                  } else if (isDocker) {
                    // 检查Docker页面是否完整
                    const hasDockerContent = document.querySelector('.page-wrapper, .container, .main-content') !== null;
                    if (!hasDockerContent) {
                      console.log('检测到Docker页面不完整，执行修复...');
                      window.location.reload(true);
                    }
                  }
                };
                
                // 点击后立即检查
                setTimeout(fixIncompletePage, 500);
                // 点击后1秒再次检查
                setTimeout(fixIncompletePage, 1000);
                // 点击后2秒最后检查
                setTimeout(fixIncompletePage, 2000);
              });
            }
          });
        }
      } catch (e) {
        console.error('启动点击监控失败:', e);
      } finally {
        // 清除计时器
        this.clickMonitorTimers.delete(tabId);
      }
    }, 1000); // 页面加载1秒后启动点击监控
    
    this.clickMonitorTimers.set(tabId, timer);
  }
  
  // 停止点击监控
  static stopClickMonitor(tabId) {
    if (this.clickMonitorTimers.has(tabId)) {
      clearTimeout(this.clickMonitorTimers.get(tabId));
      this.clickMonitorTimers.delete(tabId);
    }
  }
}

// 安全管理器 - 处理恶意事件风险
class SecurityManager {
  // 恶意请求模式
  static maliciousRequestPatterns = [
    // 常见恶意域名和路径
    /malware/i,
    /phishing/i,
    /exploit/i,
    /attack/i,
    /hack/i,
    /virus/i,
    /trojan/i,
    /ransomware/i,
    /spyware/i,
    /adware/i,
    /botnet/i,
    // 恶意参数模式
    /<script/i,
    /<iframe/i,
    /<object/i,
    /<embed/i,
    /javascript:/i,
    /vbscript:/i,
    /data:/i,
    /onerror=/i,
    /onload=/i,
    /onclick=/i,
    // SQL注入模式
    /' OR '1'='1/i,
    /union select/i,
    /drop table/i,
    /insert into/i,
    // 命令注入模式
    /\|/i,
    /&&/i,
    /;/i,
    /`/i,
    /\$/i
  ];
  
  // 恶意资源主机
  static maliciousHosts = [
    'malware.com',
    'phishing.com',
    'exploit-db.com',
    'attack-domain.com',
    'hack-tools.com',
    'virus-host.com'
  ];
  
  // 检测恶意请求
  static isMaliciousRequest(details) {
    // 检查URL是否包含恶意模式
    for (const pattern of this.maliciousRequestPatterns) {
      if (pattern.test(details.url)) {
        console.log('检测到恶意请求模式:', details.url, '匹配:', pattern);
        return true;
      }
    }
    
    // 检查主机是否为恶意主机
    const url = new URL(details.url);
    if (this.maliciousHosts.includes(url.hostname)) {
      console.log('检测到恶意主机:', details.url);
      return true;
    }
    
    // 检查请求方法是否异常
    if (!['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].includes(details.method)) {
      console.log('检测到异常请求方法:', details.method, 'URL:', details.url);
      return true;
    }
    
    // 检查请求大小是否异常（超过10MB）
    if (details.requestBody && details.requestBody.size > 10 * 1024 * 1024) {
      console.log('检测到异常请求大小:', details.requestBody.size, 'URL:', details.url);
      return true;
    }
    
    return false;
  }
  
  // 检测XSS攻击
  static isXSSAttack(details) {
    // 检查URL是否包含XSS模式
    if (/<script/i.test(details.url) || /javascript:/i.test(details.url)) {
      console.log('检测到XSS攻击:', details.url);
      return true;
    }
    
    // 检查请求体是否包含XSS模式
    if (details.requestBody && details.requestBody.formData) {
      for (const [key, values] of Object.entries(details.requestBody.formData)) {
        for (const value of values) {
          if (/<script/i.test(value) || /javascript:/i.test(value)) {
            console.log('检测到表单XSS攻击:', details.url, '参数:', key, '值:', value);
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  // 检测CSRF攻击
  static isCSRFAttack(details) {
    // 检查跨域POST请求是否缺少CSRF令牌
    if (details.method === 'POST') {
      const url = new URL(details.url);
      
      // 检查是否为跨域请求
      if (details.initiator && !details.initiator.includes(url.hostname)) {
        console.log('检测到跨域POST请求:', details.url, '发起者:', details.initiator);
        
        // 检查是否包含CSRF令牌
        let hasCsrfToken = false;
        
        // 检查请求头
        if (details.requestHeaders) {
          for (const header of details.requestHeaders) {
            if (header.name.toLowerCase() === 'x-csrf-token' || 
                header.name.toLowerCase() === 'x-requested-with' ||
                header.name.toLowerCase() === 'authorization') {
              hasCsrfToken = true;
              break;
            }
          }
        }
        
        // 检查请求体
        if (!hasCsrfToken && details.requestBody && details.requestBody.formData) {
          for (const [key] of Object.entries(details.requestBody.formData)) {
            if (key.toLowerCase().includes('csrf') || 
                key.toLowerCase().includes('token') ||
                key.toLowerCase().includes('authenticity')) {
              hasCsrfToken = true;
              break;
            }
          }
        }
        
        if (!hasCsrfToken) {
          console.log('检测到CSRF攻击风险:', details.url, '缺少CSRF令牌');
          return true;
        }
      }
    }
    
    return false;
  }
  
  // 阻止恶意请求
  static blockMaliciousRequest(details) {
    console.log('阻止恶意请求:', details.url, '原因:', details.reason);
    return { cancel: true };
  }
  
  // 设置安全头
  static setSecurityHeaders(details) {
    // 为GitHub和Docker网站添加额外的安全头
    if (details.url.includes('github.com') || 
        details.url.includes('docker.com') || 
        details.url.includes('docker.io') || 
        details.url.includes('dockerhub.com')) {
      return {
        responseHeaders: details.responseHeaders.concat([
          { name: 'X-XSS-Protection', value: '1; mode=block' },
          { name: 'X-Content-Type-Options', value: 'nosniff' },
          { name: 'X-Frame-Options', value: 'SAMEORIGIN' },
          { name: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;" },
          { name: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { name: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' }
        ])
      };
    }
    return { responseHeaders: details.responseHeaders };
  }
}

// 初始化
async function init() {
  await StorageManager.init();
  
  // 注册网络请求监听器 - 恶意请求检测
  chrome.webRequest.onBeforeRequest.addListener(
    (details) => {
      // 1. 检测恶意请求
      if (SecurityManager.isMaliciousRequest(details)) {
        return SecurityManager.blockMaliciousRequest({ ...details, reason: '恶意请求模式' });
      }
      
      // 2. 检测XSS攻击
      if (SecurityManager.isXSSAttack(details)) {
        return SecurityManager.blockMaliciousRequest({ ...details, reason: 'XSS攻击' });
      }
      
      // 3. 检测CSRF攻击
      if (SecurityManager.isCSRFAttack(details)) {
        return SecurityManager.blockMaliciousRequest({ ...details, reason: 'CSRF攻击风险' });
      }
      
      // 4. 处理140.82.113.3特殊请求
      const result = NetworkHandler.handle140_82_113_3(details);
      if (result.redirectUrl) {
        return result;
      }
      
      // 5. 处理正常请求
      if (details.url.includes('github.com')) {
        return NetworkHandler.handleGitHubRequest(details);
      } else if (details.url.includes('docker.com') || details.url.includes('docker.io') || details.url.includes('dockerhub.com')) {
        return NetworkHandler.handleDockerRequest(details);
      } else if (details.url.includes('2345')) {
        return NetworkHandler.handle2345Request(details);
      }
      return { cancel: false };
    },
    { urls: ["<all_urls>"] },
    ["blocking"]
  );
  
  // 注册响应头监听器 - 设置安全头
  chrome.webRequest.onHeadersReceived.addListener(
    (details) => {
      return SecurityManager.setSecurityHeaders(details);
    },
    { urls: ["<all_urls>"] },
    ["blocking", "responseHeaders"]
  );
  
  // 注册下载监听器
  chrome.downloads.onCreated.addListener((downloadItem) => {
    console.log('检测到下载创建:', downloadItem.url);
    
    // 检查是否为2345相关下载
    if (downloadItem.url.includes('2345')) {
      const isUnsafe = BrowserSecurityFixer.isUnsafeDownload(downloadItem.url);
      if (isUnsafe) {
        console.log('检测到不安全的2345下载，正在取消:', downloadItem.url);
        chrome.downloads.cancel(downloadItem.id);
      }
    }
  });
  
  // 监听请求错误
  chrome.webRequest.onErrorOccurred.addListener(
    (details) => {
      // 只处理目标网站的请求错误
      if (details.url.includes('github.com') || 
          details.url.includes('docker.com') || 
          details.url.includes('docker.io') || 
          details.url.includes('dockerhub.com')) {
        NetworkHandler.handleRequestError(details);
      }
    },
    { urls: ["<all_urls>"] }
  );
  
  // 监听请求完成
  chrome.webRequest.onCompleted.addListener(
    (details) => {
      // 只处理目标网站的请求完成事件
      if (details.url.includes('github.com') || 
          details.url.includes('docker.com') || 
          details.url.includes('docker.io') || 
          details.url.includes('dockerhub.com')) {
        NetworkHandler.handleRequestCompleted(details);
      }
    },
    { urls: ["<all_urls>"] }
  );
  
  // 监听标签页更新
  chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (!tab.url) return;
    
    // 检查是否为目标网站
    const isTargetSite = tab.url.includes('github.com') || 
                        tab.url.includes('docker.com') || 
                        tab.url.includes('docker.io') || 
                        tab.url.includes('dockerhub.com');
    
    if (!isTargetSite) return;
    
    if (changeInfo.status === 'loading') {
      // 发送初始化消息
      chrome.tabs.sendMessage(tabId, {
        type: 'INIT_PROGRESS'
      });
      
      // 启动页面加载超时监控
      BlankPageFixer.startPageLoadMonitor(tabId, tab.url);
    } else if (changeInfo.status === 'complete') {
      // 页面加载完成，停止超时监控
      BlankPageFixer.stopPageLoadMonitor(tabId);
      
      // 检测并修复空白页面
      setTimeout(async () => {
        await BlankPageFixer.fixBlankPage(tabId, tab.url);
      }, 500);
      
      // 启动点击监控，确保每次点击都能访问到完整页面
      BlankPageFixer.startClickMonitor(tabId, tab.url);
    }
  });
  
  // 监听标签页移除，清理资源
  chrome.tabs.onRemoved.addListener((tabId) => {
    // 停止页面加载监控
    BlankPageFixer.stopPageLoadMonitor(tabId);
    
    // 停止点击监控
    BlankPageFixer.stopClickMonitor(tabId);
    
    // 清理该标签页的所有重试计数
    for (const [key, _value] of NetworkHandler.retryCount.entries()) {
      if (key.startsWith(`${tabId}-`)) {
        NetworkHandler.retryCount.delete(key);
      }
    }
  });
}

// 启动初始化
init();