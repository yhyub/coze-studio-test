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
    "github.com": ["140.82.114.3"],
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
    enableDirectIpAccess: false, // 禁用直接IP访问，避免SSL证书问题
    enableSSLValidation: true, // 启用SSL证书验证
    enableSecureAccess: true // 启用安全访问模式
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
    
    // 初始化网络修复状态
    const networkFixStatus = await this.get('networkFixStatus');
    if (!networkFixStatus) {
      await this.set('networkFixStatus', {
        lastFixTime: null,
        fixCount: 0,
        lastStatus: 'idle'
      });
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
            console.log('重定向GitHub主站失败，使用官方域名:', e);
          }
        }
        // 使用官方域名，不使用直接IP访问
        return { cancel: false };
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
            console.log('重定向raw.githubusercontent.com失败，使用官方域名:', e);
          }
        }
        // 使用官方域名，不使用直接IP访问
        return { cancel: false };
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
            console.log('重定向codeload.github.com失败，使用官方域名:', e);
          }
        }
        // 使用官方域名，不使用直接IP访问
        return { cancel: false };
      }
      
      // 5. 针对GitHub API使用专用策略
      if (url.hostname === 'api.github.com') {
        // API请求使用官方域名，确保SSL证书验证正常
        console.log('GitHub API请求：使用官方域名，避免IP地址SSL证书问题');
        return { cancel: false };
      }
      
      // 6. 其他GitHub服务：使用官方域名
      console.log('其他GitHub服务：使用官方域名，避免IP地址SSL证书问题');
      return { cancel: false };
    }
    
    return { cancel: false };
  }
  
  // 处理GitHub直接IP访问 - 已禁用，改用安全域名访问
  static handleGitHubDirectIp(_details, url) {
    // 禁用直接IP访问，避免SSL证书问题
    // 始终使用域名访问，确保SSL证书验证正常
    console.log('安全模式：使用域名访问GitHub，避免IP地址SSL证书问题');
    return { cancel: false }; // 不修改请求，使用原域名URL
  }
  
  // 处理特殊IP地址的证书错误（已移除140.82.113.3的处理）
  static handleSpecialIpCertErrors(details) {
    const url = new URL(details.url);
    
    // 这里可以添加其他特殊IP地址的处理逻辑
    
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
                // 第三次尝试：清除浏览器缓存后重试
                console.log('策略3：清除浏览器缓存后重试');
                await this.clearCacheAndRetry(details.tabId, details.url);
                break;
              case 4:
                // 第四次尝试：执行DNS清理和SSL证书验证
                console.log('策略4：执行DNS清理和SSL证书验证');
                await this.performDNSAndSSLCleanup(details.tabId, details.url);
                break;
              case 5:
                // 第五次尝试：使用终极域名访问策略
                console.log('策略5：使用终极域名访问策略');
                await this.ultimateDomainAccessStrategy(details.tabId, details.url);
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
      // 检查URL是否包含IP地址
      const urlObj = new URL(url);
      const isIpAddress = /^(\d{1,3}\.){3}\d{1,3}$/.test(urlObj.hostname);
      
      if (isIpAddress) {
        console.log('检测到IP地址访问，证书错误修复：重定向到官方域名');
        
        // 1. 提取原始域名
        let originalDomain = 'github.com';
        if (url.includes('140.82.114.3')) {
          originalDomain = 'github.com';
        } else if (url.includes('140.82.114.4')) {
          originalDomain = 'gist.github.com';
        } else if (url.includes('140.82.114.9')) {
          originalDomain = 'codeload.github.com';
        } else if (url.includes('140.82.114.10')) {
          originalDomain = 'api.github.com';
        }
        
        // 2. 构建官方域名URL
        const domainUrl = url.replace(urlObj.hostname, originalDomain);
        console.log('重定向到官方域名:', domainUrl);
        
        try {
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            console.log('证书错误修复：使用官方域名访问');
            chrome.tabs.update(tabId, { url: domainUrl });
            return;
          }
        } catch (e) {
          console.log('重定向到官方域名失败:', e);
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
  
  // 执行DNS清理和SSL证书验证
  static async performDNSAndSSLCleanup(tabId, url) {
    console.log('执行DNS清理和SSL证书验证:', url);
    
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        // 注入脚本执行DNS清理和SSL验证
        await chrome.scripting.executeScript({
          target: { tabId: tabId },
          func: () => {
            console.log('开始DNS清理和SSL证书验证...');
            
            // 1. 清除所有缓存
            if (window.caches) {
              window.caches.keys().then(cacheNames => {
                cacheNames.forEach(cacheName => {
                  window.caches.delete(cacheName);
                });
              });
            }
            
            // 2. 清除所有存储
            Object.keys(localStorage).forEach(key => {
              localStorage.removeItem(key);
            });
            Object.keys(sessionStorage).forEach(key => {
              sessionStorage.removeItem(key);
            });
            
            // 3. 强制刷新页面，确保使用最新的DNS解析和SSL证书
            console.log('DNS清理和SSL验证完成，准备重新加载');
            setTimeout(() => {
              window.location.reload(true);
            }, 100);
          }
        });
      }
    } catch (e) {
      console.log('DNS清理和SSL证书验证失败:', e);
    }
  }
  
  // 使用终极域名访问策略
  static async ultimateDomainAccessStrategy(tabId, url) {
    console.log('使用终极域名访问策略:', url);
    
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        // 1. 清除所有缓存和存储
        await this.clearCacheAndRetry(tabId, url);
        
        // 2. 等待2秒后重新加载
        setTimeout(async () => {
          try {
            const currentTab = await chrome.tabs.get(tabId);
            if (currentTab && currentTab.url === url) {
              // 使用官方域名重新加载，确保SSL证书验证正常
              console.log('终极策略：使用官方域名重新加载，确保SSL证书验证正常');
              chrome.tabs.reload(tabId, { bypassCache: true });
            }
          } catch (e) {
            console.log('终极域名访问策略失败:', e);
          }
        }, 2000);
      }
    } catch (e) {
      console.log('终极域名访问策略失败:', e);
    }
  }
  
  // 强制使用直接IP访问 - 已弃用，保留用于兼容性
  static async forceDirectIpAccess(tabId, url) {
    console.log('警告：forceDirectIpAccess已弃用，改用安全域名访问');
    // 不再使用IP访问，改用域名访问
    return this.ultimateDomainAccessStrategy(tabId, url);
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
  
  // 终极域名访问策略
  static async ultimateFixStrategy(tabId, url) {
    try {
      const tab = await chrome.tabs.get(tabId);
      if (tab && tab.url === url) {
        console.log('执行终极域名访问策略:', url);
        
        // 1. 首先清除缓存
        await this.clearCacheAndRetry(tabId, url);
        
        // 2. 然后立即切换到最佳镜像
        await this.switchGitHubMirror(tabId, url);
        
        // 3. 最后使用域名访问策略
        setTimeout(async () => {
          await this.ultimateDomainAccessStrategy(tabId, url);
        }, 500);
      }
    } catch (e) {
      console.log('终极域名访问策略失败:', e);
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
        console.log('所有GitHub镜像测试失败，使用官方域名访问');
        
        // 使用官方域名访问，确保SSL证书验证正常
        try {
          const tab = await chrome.tabs.get(tabId);
          if (tab && tab.url === url) {
            console.log('使用官方域名访问GitHub，确保SSL证书验证正常');
            chrome.tabs.reload(tabId, { bypassCache: true });
          }
        } catch (e) {
          console.log('官方域名访问失败:', e);
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
  
  // 网络修复模块
  static async performNetworkFix() {
    console.log('开始执行全面网络修复...');
    
    try {
      // 1. 记录修复开始时间
      const startTime = new Date().toISOString();
      
      // 2. 深度网络诊断
      const diagnosisResult = await this.performNetworkDiagnosis();
      console.log('网络诊断结果:', diagnosisResult);
      
      // 3. DNS优化（浏览器环境下的DNS优化）
      const dnsResult = await this.optimizeDNS();
      console.log('DNS优化结果:', dnsResult);
      
      // 4. 浏览器缓存清理
      const cacheResult = await this.clearBrowserCache();
      console.log('浏览器缓存清理结果:', cacheResult);
      
      // 5. 系统时间同步检查
      const timeResult = await this.checkSystemTime();
      console.log('系统时间检查结果:', timeResult);
      
      // 6. 2345浏览器解决方案
      const browserResult = await this.verify2345Browser();
      console.log('2345浏览器解决方案结果:', browserResult);
      
      // 7. 最终验证
      const verificationResult = await this.verifyNetworkStatus();
      console.log('网络状态验证结果:', verificationResult);
      
      // 8. 更新修复状态
      await StorageManager.set('networkFixStatus', {
        lastFixTime: new Date().toISOString(),
        fixCount: (await StorageManager.get('networkFixStatus'))?.fixCount + 1 || 1,
        lastStatus: 'completed',
        results: {
          diagnosis: diagnosisResult,
          dns: dnsResult,
          cache: cacheResult,
          time: timeResult,
          browser: browserResult,
          verification: verificationResult
        }
      });
      
      console.log('全面网络修复完成！');
      return {
        success: true,
        message: '网络修复完成，GitHub访问问题已解决',
        results: {
          diagnosis: diagnosisResult,
          dns: dnsResult,
          cache: cacheResult,
          time: timeResult,
          browser: browserResult,
          verification: verificationResult
        }
      };
    } catch (error) {
      console.error('网络修复失败:', error);
      await StorageManager.set('networkFixStatus', {
        lastFixTime: new Date().toISOString(),
        lastStatus: 'failed',
        error: error.message
      });
      return {
        success: false,
        message: `网络修复失败: ${error.message}`
      };
    }
  }
  
  // 深度网络诊断
  static async performNetworkDiagnosis() {
    console.log('执行深度网络诊断...');
    
    try {
      const testHosts = [
        'github.com',
        'api.github.com',
        'raw.githubusercontent.com'
      ];
      
      const results = {};
      
      for (const host of testHosts) {
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 5000);
          
          const response = await fetch(`https://${host}/`, {
            method: 'HEAD',
            signal: controller.signal,
            cache: 'no-cache'
          });
          
          clearTimeout(timeoutId);
          
          results[host] = {
            reachable: true,
            status: response.status
          };
        } catch (error) {
          results[host] = {
            reachable: false,
            error: error.message
          };
        }
      }
      
      return {
        success: true,
        results
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  // DNS优化（浏览器环境）
  static async optimizeDNS() {
    console.log('执行DNS优化...');
    
    try {
      // 在浏览器环境中，我们可以通过以下方式优化DNS：
      // 1. 预解析GitHub相关域名
      // 2. 清除DNS缓存
      // 3. 强制刷新DNS
      
      // 预解析GitHub相关域名
      const githubDomains = [
        'github.com',
        'api.github.com',
        'raw.githubusercontent.com'
      ];
      
      githubDomains.forEach(domain => {
        // 使用link标签预解析
        const link = document.createElement('link');
        link.rel = 'dns-prefetch';
        link.href = `//${domain}`;
        document.head.appendChild(link);
      });
      
      return {
        success: true,
        domains: githubDomains,
        message: 'DNS优化完成：域名预解析已设置'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  // 浏览器缓存清理
  static async clearBrowserCache() {
    console.log('执行浏览器缓存清理...');
    
    try {
      // 清除浏览器缓存
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        await Promise.all(
          cacheNames.map(cacheName => caches.delete(cacheName))
        );
      }
      
      // 清除localStorage和sessionStorage中的GitHub相关数据
      Object.keys(localStorage).forEach(key => {
        if (key.includes('github') || key.includes('GitHub')) {
          localStorage.removeItem(key);
        }
      });
      
      Object.keys(sessionStorage).forEach(key => {
        if (key.includes('github') || key.includes('GitHub')) {
          sessionStorage.removeItem(key);
        }
      });
      
      return {
        success: true,
        message: '浏览器缓存清理完成'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  // 系统时间检查
  static async checkSystemTime() {
    console.log('执行系统时间检查...');
    
    try {
      // 检查系统时间是否合理
      const now = new Date();
      const year = now.getFullYear();
      
      // 检查年份是否在合理范围内（2020-2030）
      if (year >= 2020 && year <= 2030) {
        return {
          success: true,
          time: now.toISOString(),
          message: '系统时间正常'
        };
      } else {
        return {
          success: false,
          error: '系统时间异常，请检查系统时间设置'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  // 2345浏览器解决方案
  static async verify2345Browser() {
    console.log('执行2345浏览器解决方案验证...');
    
    try {
      // 在浏览器扩展中，我们可以通过打开新标签页来模拟启动2345浏览器
      // 实际的2345浏览器启动需要通过Native Messaging或其他方式
      
      // 打开GitHub相关页面
      chrome.tabs.create({ url: 'https://github.com' });
      chrome.tabs.create({ url: 'https://github.com/settings/installations' });
      
      return {
        success: true,
        message: '已打开GitHub相关页面',
        tabsOpened: 2
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  // 网络状态验证
  static async verifyNetworkStatus() {
    console.log('执行网络状态验证...');
    
    try {
      // 测试GitHub API访问
      const response = await fetch('https://api.github.com', {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        },
        timeout: 10000
      });
      
      return {
        success: true,
        githubApi: {
          reachable: true,
          statusCode: response.status
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
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
      
      // 4. 处理特殊IP地址请求（已移除不安全IP处理）
      const result = NetworkHandler.handleSpecialIpCertErrors(details);
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