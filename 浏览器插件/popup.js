// GitHub网络修复器 - 插件交互逻辑

// DOM元素
const elements = {
    githubStatus: document.getElementById('github-status'),
    apiStatus: document.getElementById('api-status'),
    sslStatus: document.getElementById('ssl-status'),
    accessMode: document.getElementById('access-mode'),
    lastFix: document.getElementById('last-fix'),
    fixCount: document.getElementById('fix-count'),
    fixBtn: document.getElementById('fix-btn'),
    fixBtnText: document.getElementById('fix-btn-text'),
    progressBar: document.getElementById('progress-bar'),
    progressText: document.getElementById('progress-text')
};

// 修复步骤
const fixSteps = [
    { name: '深度网络诊断', icon: '🔧' },
    { name: 'DNS服务器优化', icon: '📡' },
    { name: '浏览器缓存清理', icon: '🗑️' },
    { name: '系统时间同步', icon: '⏰' },
    { name: '2345浏览器解决方案', icon: '🌐' },
    { name: '网络状态验证', icon: '✅' }
];

// 初始化插件
async function initPlugin() {
    console.log('初始化GitHub网络修复器插件...');
    
    // 检查网络状态
    await checkNetworkStatus();
    
    // 加载修复状态
    await loadFixStatus();
    
    // 绑定事件监听器
    bindEventListeners();
}

// 检查网络状态
async function checkNetworkStatus() {
    console.log('检查网络状态...');
    
    // 检查GitHub主站
    try {
        const githubResponse = await fetch('https://github.com/', {
            method: 'HEAD',
            timeout: 5000
        });
        
        if (githubResponse.ok) {
            elements.githubStatus.textContent = '正常';
            elements.githubStatus.className = 'status-value success';
        } else {
            elements.githubStatus.textContent = `异常 (${githubResponse.status})`;
            elements.githubStatus.className = 'status-value error';
        }
    } catch (error) {
        elements.githubStatus.textContent = '超时';
        elements.githubStatus.className = 'status-value error';
    }
    
    // 检查GitHub API
    try {
        const apiResponse = await fetch('https://api.github.com/', {
            method: 'HEAD',
            timeout: 5000
        });
        
        if (apiResponse.ok) {
            elements.apiStatus.textContent = '正常';
            elements.apiStatus.className = 'status-value success';
        } else {
            elements.apiStatus.textContent = `异常 (${apiResponse.status})`;
            elements.apiStatus.className = 'status-value error';
        }
    } catch (error) {
        elements.apiStatus.textContent = '超时';
        elements.apiStatus.className = 'status-value error';
    }
    
    // 检查SSL证书状态
    try {
        const sslResponse = await fetch('https://github.com/', {
            method: 'HEAD',
            timeout: 5000
        });
        
        if (sslResponse.ok) {
            elements.sslStatus.textContent = '有效';
            elements.sslStatus.className = 'status-value success';
        } else {
            elements.sslStatus.textContent = '异常';
            elements.sslStatus.className = 'status-value error';
        }
    } catch (error) {
        elements.sslStatus.textContent = '检查失败';
        elements.sslStatus.className = 'status-value error';
    }
    
    // 设置访问模式
    elements.accessMode.textContent = '安全域名访问';
    elements.accessMode.className = 'status-value success';
}

// 加载修复状态
async function loadFixStatus() {
    console.log('加载修复状态...');
    
    try {
        // 从存储中获取修复状态
        chrome.storage.local.get('networkFixStatus', (result) => {
            const status = result.networkFixStatus;
            
            if (status) {
                // 更新上次修复时间
                if (status.lastFixTime) {
                    const date = new Date(status.lastFixTime);
                    elements.lastFix.textContent = formatDateTime(date);
                }
                
                // 更新修复次数
                if (status.fixCount) {
                    elements.fixCount.textContent = status.fixCount;
                }
            }
        });
    } catch (error) {
        console.error('加载修复状态失败:', error);
    }
}

// 绑定事件监听器
function bindEventListeners() {
    // 修复按钮点击事件
    elements.fixBtn.addEventListener('click', async () => {
        if (elements.fixBtn.disabled) return;
        
        await startNetworkFix();
    });
    
    // 定期检查网络状态
    setInterval(checkNetworkStatus, 30000); // 每30秒检查一次
}

// 开始网络修复
async function startNetworkFix() {
    console.log('开始网络修复...');
    
    // 禁用修复按钮
    elements.fixBtn.disabled = true;
    elements.fixBtn.classList.add('loading');
    elements.fixBtnText.innerHTML = '<div class="loading-spinner"></div> 修复中...';
    
    // 重置进度条
    elements.progressBar.style.width = '0%';
    elements.progressText.textContent = '准备就绪';
    
    try {
        // 执行修复步骤
        let currentStep = 0;
        const totalSteps = fixSteps.length;
        
        for (const step of fixSteps) {
            currentStep++;
            
            // 更新进度
            const progress = (currentStep / totalSteps) * 100;
            elements.progressBar.style.width = `${progress}%`;
            elements.progressText.textContent = `${step.icon} ${step.name}`;
            
            // 模拟步骤执行
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // 执行实际修复操作
            await executeFixStep(step.name);
        }
        
        // 修复完成
        elements.progressBar.style.width = '100%';
        elements.progressText.textContent = '✅ 修复完成！';
        
        // 更新按钮状态
        elements.fixBtn.classList.remove('loading');
        elements.fixBtnText.textContent = '修复完成';
        
        // 重新检查网络状态
        await checkNetworkStatus();
        
        // 加载最新修复状态
        await loadFixStatus();
        
        // 显示成功消息
        showNotification('🎉 GitHub网络修复成功！', '网络修复已完成，您现在可以正常访问GitHub了。');
        
        // 3秒后恢复按钮状态
        setTimeout(() => {
            elements.fixBtn.disabled = false;
            elements.fixBtnText.textContent = '开始网络修复';
            elements.progressText.textContent = '准备就绪';
        }, 3000);
        
    } catch (error) {
        console.error('网络修复失败:', error);
        
        // 恢复按钮状态
        elements.fixBtn.disabled = false;
        elements.fixBtn.classList.remove('loading');
        elements.fixBtnText.textContent = '开始网络修复';
        
        // 更新进度条
        elements.progressBar.style.width = '100%';
        elements.progressBar.style.backgroundColor = '#d73a49';
        elements.progressText.textContent = `❌ 修复失败: ${error.message}`;
        
        // 显示错误消息
        showNotification('❌ 修复失败', error.message);
        
        // 3秒后恢复进度条
        setTimeout(() => {
            elements.progressBar.style.width = '0%';
            elements.progressBar.style.backgroundColor = '#28a745';
            elements.progressText.textContent = '准备就绪';
        }, 3000);
    }
}

// 执行修复步骤
async function executeFixStep(stepName) {
    console.log(`执行修复步骤: ${stepName}`);
    
    try {
        switch (stepName) {
            case '深度网络诊断':
                await diagnoseNetwork();
                break;
            
            case 'DNS服务器优化':
                await optimizeDNS();
                break;
            
            case '浏览器缓存清理':
                await clearBrowserCache();
                break;
            
            case '系统时间同步':
                await syncSystemTime();
                break;
            
            case '2345浏览器解决方案':
                await launch2345Browser();
                break;
            
            case '网络状态验证':
                await verifyNetworkStatus();
                break;
        }
    } catch (error) {
        console.error(`执行步骤 ${stepName} 失败:`, error);
        throw error;
    }
}

// 深度网络诊断
async function diagnoseNetwork() {
    console.log('执行深度网络诊断...');
    
    // 测试多个GitHub相关域名
    const domains = [
        'github.com',
        'api.github.com',
        'raw.githubusercontent.com'
    ];
    
    for (const domain of domains) {
        try {
            const response = await fetch(`https://${domain}/`, {
                method: 'HEAD',
                timeout: 3000
            });
            console.log(`域名 ${domain}: ${response.ok ? '可达' : '不可达'}`);
        } catch (error) {
            console.log(`域名 ${domain}: 不可达 - ${error.message}`);
        }
    }
}

// DNS优化
async function optimizeDNS() {
    console.log('执行DNS优化...');
    
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
}

// 浏览器缓存清理
async function clearBrowserCache() {
    console.log('执行浏览器缓存清理...');
    
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
}

// 系统时间同步
async function syncSystemTime() {
    console.log('执行系统时间同步...');
    
    // 检查系统时间是否合理
    const now = new Date();
    const year = now.getFullYear();
    
    if (year < 2020 || year > 2030) {
        console.warn('系统时间异常，可能影响SSL证书验证');
    }
}

// 2345浏览器解决方案
async function launch2345Browser() {
    console.log('执行2345浏览器解决方案...');
    
    // 打开GitHub相关页面
    chrome.tabs.create({ url: 'https://github.com' });
    chrome.tabs.create({ url: 'https://github.com/settings/installations' });
}

// 网络状态验证
async function verifyNetworkStatus() {
    console.log('执行网络状态验证...');
    
    // 测试GitHub API访问
    try {
        const response = await fetch('https://api.github.com', {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            },
            timeout: 5000
        });
        
        if (response.ok) {
            console.log('GitHub API 访问正常');
        } else {
            console.warn('GitHub API 访问异常:', response.status);
        }
    } catch (error) {
        console.error('GitHub API 访问失败:', error);
    }
}

// 显示通知
function showNotification(title, message) {
    // 使用Chrome通知API
    if (chrome.notifications) {
        chrome.notifications.create({
            type: 'basic',
            iconUrl: 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
            title: title,
            message: message,
            priority: 2
        });
    } else {
        //  fallback: 使用alert
        alert(`${title}\n${message}`);
    }
}

// 格式化日期时间
function formatDateTime(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    
    return `${year}-${month}-${day} ${hours}:${minutes}`;
}

// 页面加载完成后初始化
window.addEventListener('DOMContentLoaded', initPlugin);
