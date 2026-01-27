// 内容脚本 - 处理页面交互和进度条显示

// 创建进度条
const progressBar = document.createElement('div');
progressBar.id = 'docker-github-progress-bar';
progressBar.style.cssText = `
  position: fixed;
  top: 0;
  left: 0;
  height: 4px;
  background: linear-gradient(90deg, #4CAF50, #2196F3, #9C27B0);
  z-index: 999999;
  transition: width 0.2s ease, opacity 0.3s ease;
  border-radius: 0 2px 2px 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  opacity: 1;
`;
document.body.appendChild(progressBar);

// 创建状态指示器
const statusIndicator = document.createElement('div');
statusIndicator.id = 'docker-github-status-indicator';
statusIndicator.style.cssText = `
  position: fixed;
  top: 10px;
  right: 10px;
  width: 20px;
  height: 20px;
  background-color: #f44336;
  border-radius: 50%;
  z-index: 999998;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  cursor: pointer;
  opacity: 0;
  pointer-events: none;
`;
document.body.appendChild(statusIndicator);

// 更新进度
function updateProgress(progress) {
  progress = Math.min(progress, 100);
  progressBar.style.width = `${progress}%`;
  
  // 更新状态指示器颜色
  let color = '#f44336';
  if (progress > 0 && progress < 30) {
    color = '#ff9800';
  } else if (progress >= 30 && progress < 70) {
    color = '#ffeb3b';
  } else if (progress >= 70) {
    color = '#4caf50';
  }
  statusIndicator.style.backgroundColor = color;
  
  if (progress > 0) {
    statusIndicator.style.opacity = '1';
    statusIndicator.style.pointerEvents = 'auto';
  }
  
  // 更新最后进度更新时间
  lastProgressUpdate = Date.now();
  
  if (progress >= 100) {
    // 页面加载完成，清理超时计时器
    if (progressTimeout) {
      clearTimeout(progressTimeout);
      progressTimeout = null;
    }
    
    setTimeout(() => {
      progressBar.style.opacity = '0';
      statusIndicator.style.opacity = '0';
      setTimeout(() => {
        progressBar.style.width = '0%';
        progressBar.style.opacity = '1';
        statusIndicator.style.pointerEvents = 'none';
      }, 300);
    }, 500);
  }
}

// 消息监听器
chrome.runtime.onMessage.addListener((message) => {
  if (message.type === 'UPDATE_PROGRESS') {
    updateProgress(message.progress);
  } else if (message.type === 'SHOW_FIX_SUGGESTION') {
    showFixSuggestion(message.message);
  }
});

// 显示修复建议
function showFixSuggestion(message) {
  // 创建修复建议容器
  const suggestionContainer = document.createElement('div');
  suggestionContainer.id = 'docker-github-fix-suggestion';
  suggestionContainer.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    padding: 15px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 10px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
    z-index: 999999;
    max-width: 300px;
    font-family: Arial, sans-serif;
    animation: slideIn 0.3s ease-out;
  `;
  
  // 添加动画
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideIn {
      from {
        transform: translateY(100%);
        opacity: 0;
      }
      to {
        transform: translateY(0);
        opacity: 1;
      }
    }
  `;
  document.head.appendChild(style);
  
  // 建议内容
  suggestionContainer.innerHTML = `
    <h3 style="margin: 0 0 10px 0; font-size: 16px;">GitHub连接修复建议</h3>
    <p style="margin: 0 0 15px 0; font-size: 14px; line-height: 1.5;">${message}</p>
    <div style="display: flex; gap: 10px;">
      <button style="
        flex: 1;
        padding: 8px;
        border: none;
        border-radius: 5px;
        background: rgba(255, 255, 255, 0.2);
        color: white;
        cursor: pointer;
        font-size: 13px;
        transition: background 0.3s ease;
      ">知道了</button>
      <button style="
        flex: 1;
        padding: 8px;
        border: none;
        border-radius: 5px;
        background: white;
        color: #667eea;
        cursor: pointer;
        font-size: 13px;
        transition: background 0.3s ease;
      ">查看详情</button>
    </div>
  `;
  
  // 添加到页面
  document.body.appendChild(suggestionContainer);
  
  // 绑定按钮事件
  const buttons = suggestionContainer.querySelectorAll('button');
  buttons[0].addEventListener('click', () => {
    suggestionContainer.remove();
    style.remove();
  });
  
  buttons[1].addEventListener('click', () => {
    // 打开GitHub修复帮助页面
    window.open('https://github.com/settings/connections/developer', '_blank');
    suggestionContainer.remove();
    style.remove();
  });
  
  // 30秒后自动消失
  setTimeout(() => {
    if (suggestionContainer.parentNode) {
      suggestionContainer.remove();
      style.remove();
    }
  }, 30000);
}

// 初始化
updateProgress(0);

// 页面加载状态监控
let startTime = Date.now();
let isPageLoaded = false;

// 页面加载事件
window.addEventListener('load', () => {
  isPageLoaded = true;
  updateProgress(100);
  console.log('页面加载完成，耗时:', Date.now() - startTime, 'ms');
});

// DOM加载完成
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    updateProgress(50);
    console.log('DOM加载完成，耗时:', Date.now() - startTime, 'ms');
  });
} else {
  updateProgress(50);
}

// 资源加载监控
let resourcesLoaded = 0;
let totalResources = 0;
let maxResources = 0;
let progressTimeout = null;
let lastProgressUpdate = Date.now();

// 确保进度条最终完成的超时机制
function ensureProgressCompletion() {
  // 如果页面加载完成，不需要干预
  if (isPageLoaded) {
    return;
  }
  
  const currentTime = Date.now();
  const timeSinceLastUpdate = currentTime - lastProgressUpdate;
  
  // 如果超过10秒没有更新进度，手动推进
  if (timeSinceLastUpdate > 10000) {
    console.log('进度条长时间无更新，手动推进进度');
    
    // 获取当前进度（基于已加载资源）
    let currentProgress = 0;
    if (maxResources > 0) {
      currentProgress = Math.min(Math.round((resourcesLoaded / maxResources) * 70), 70);
    }
    
    // 手动推进进度，每次增加10%
    const newProgress = Math.min(currentProgress + 10, 90);
    updateProgress(newProgress);
    
    // 30秒后强制完成
    if (currentTime - startTime > 30000) {
      console.log('页面加载超时，强制完成进度条');
      updateProgress(100);
      isPageLoaded = true;
      return;
    }
    
    // 1秒后再次检查
    progressTimeout = setTimeout(ensureProgressCompletion, 1000);
  } else {
    // 5秒后再次检查
    progressTimeout = setTimeout(ensureProgressCompletion, 5000);
  }
}

// 监控资源加载
const observer = new PerformanceObserver((list) => {
  const entries = list.getEntries();
  totalResources += entries.length;
  maxResources = Math.max(maxResources, totalResources);
  
  let updated = false;
  entries.forEach((entry) => {
    // 无论资源是否成功加载，都计入已加载资源
    if (entry.loadEventEnd > 0 || entry.duration > 0) {
      resourcesLoaded++;
      updated = true;
    }
  });
  
  if (updated) {
    // 更新进度
    const progress = Math.min(Math.round((resourcesLoaded / maxResources) * 70), 70);
    updateProgress(progress);
    lastProgressUpdate = Date.now();
  }
});

// 开始监控
observer.observe({ entryTypes: ['resource'] });

// 启动进度完成确保机制
ensureProgressCompletion();

// 检测页面是否卡住或无法访问
let lastActivityTime = Date.now();
let stuckCheckInterval;
let clickEventCount = 0;

// 增强的页面状态检查函数
function checkPageStatus() {
  const currentTime = Date.now();
  
  // 获取当前URL
  const currentUrl = window.location.href;
  const isGitHub = currentUrl.includes('github.com');
  const isDocker = currentUrl.includes('docker.com') || currentUrl.includes('docker.io') || currentUrl.includes('dockerhub.com');
  
  // 情况1：页面未加载完成且超过20秒没有活动（蓝色圈问题，缩短超时时间）
  if (!isPageLoaded && currentTime - lastActivityTime > 20000) {
    console.log('检测到页面可能卡住，重新加载...');
    window.location.reload(true);
    return;
  }
  
  // 情况2：页面已加载但内容极少（空白页面问题）
  if (isPageLoaded && document.body && document.body.innerHTML.trim() && 
      !document.querySelector('main, #content, .container, .App') &&
      document.querySelectorAll('div, p, h1, h2, h3, h4, h5, h6, img').length < 5) {
    console.log('检测到内容极少的页面，重新加载...');
    setTimeout(() => {
      window.location.reload(true);
    }, 1000);
    return;
  }
  
  // 情况3：完全空白页面
  if (document.body && document.body.innerHTML.trim() === '') {
    console.log('检测到完全空白页面，重新加载...');
    window.location.reload(true);
    return;
  }
  
  // 情况4：GitHub特定空白页面检查
  if (isGitHub && isPageLoaded) {
    // 检查是否有GitHub特有的内容区域
    const hasGitHubContent = document.querySelector('#js-pjax-container, .application-main, #repository-container-header') !== null;
    if (!hasGitHubContent) {
      console.log('检测到GitHub特定空白页面，执行修复...');
      window.location.reload(true);
      return;
    }
  }
  
  // 情况5：Docker特定空白页面检查
  if (isDocker && isPageLoaded) {
    // 检查是否有Docker特有的内容区域
    const hasDockerContent = document.querySelector('.page-wrapper, .container, .main-content') !== null;
    if (!hasDockerContent) {
      console.log('检测到Docker特定空白页面，执行修复...');
      window.location.reload(true);
      return;
    }
  }
  
  // 情况6：检测到无法访问的错误页面
  const errorMessages = [
    '无法访问此网站',
    'This site can\'t be reached',
    'ERR_CONNECTION_TIMED_OUT',
    'ERR_NAME_NOT_RESOLVED',
    'ERR_CONNECTION_REFUSED',
    '404 Not Found',
    '500 Internal Server Error',
    '502 Bad Gateway',
    '503 Service Unavailable'
  ];
  
  const bodyText = document.body ? document.body.textContent || document.body.innerText : '';
  const hasErrorMessage = errorMessages.some(msg => bodyText.includes(msg));
  
  if (hasErrorMessage) {
    console.log('检测到无法访问的错误页面，重新加载...');
    setTimeout(() => {
      window.location.reload(true);
    }, 1000);
    return;
  }
  
  // 情况7：检查网络连接
  if (!navigator.onLine) {
    console.log('检测到网络断开，等待重新连接...');
    const checkConnection = () => {
      if (navigator.onLine) {
        console.log('网络已恢复，重新加载页面...');
        window.location.reload(true);
        window.removeEventListener('online', checkConnection);
      }
    };
    window.addEventListener('online', checkConnection);
    return;
  }
}

// 增强的点击事件处理函数
function handlePageClick(event) {
  lastActivityTime = Date.now();
  clickEventCount++;
  
  console.log(`检测到页面点击 (${clickEventCount})，启动修复监控...`);
  
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
}

// 监听页面活动
const activityEvents = ['mousemove', 'keydown', 'scroll', 'click'];
activityEvents.forEach(event => {
  window.addEventListener(event, () => {
    lastActivityTime = Date.now();
    
    // 特别处理点击事件
    if (event === 'click') {
      handlePageClick(event);
    }
  });
});

// 定期检查页面状态
stuckCheckInterval = setInterval(checkPageStatus, 5000);

// 3分钟后停止检查
setTimeout(() => {
  clearInterval(stuckCheckInterval);
}, 180000);

// 添加页面加载完成后的额外检查
window.addEventListener('load', () => {
  console.log('页面加载完成，执行最终完整性检查...');
  
  // 延迟1秒执行最终检查，确保所有资源都已加载
  setTimeout(() => {
    checkPageStatus();
  }, 1000);
});

// 点击状态指示器显示调试信息
statusIndicator.addEventListener('click', () => {
  const debugInfo = {
    pageLoaded: isPageLoaded,
    loadTime: isPageLoaded ? Date.now() - startTime : '仍在加载中',
    resourcesLoaded: resourcesLoaded,
    totalResources: totalResources,
    maxResources: maxResources,
    bodyContentLength: document.body ? document.body.innerHTML.length : 0,
    elementCount: document.querySelectorAll('*').length
  };
  console.log('调试信息:', debugInfo);
  alert('页面加载信息:\n' + JSON.stringify(debugInfo, null, 2));
});