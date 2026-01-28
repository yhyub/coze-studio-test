import React, { useState, useEffect } from 'react';
import { Shield, Lock, Key, Smartphone, AlertTriangle, CheckCircle, ChevronRight, Eye, EyeOff, RefreshCw } from '@heroicons/react/24/outline';

interface SecuritySetting {
  id: string;
  name: string;
  description: string;
  status: 'enabled' | 'disabled' | 'warning';
  action: string;
}

const SecuritySettings: React.FC = () => {
  const [securityScore, setSecurityScore] = useState(75);
  const [securitySettings, setSecuritySettings] = useState<SecuritySetting[]>([]);
  const [passwordStrength, setPasswordStrength] = useState('medium');
  const [showPassword, setShowPassword] = useState(false);
  const [lastSecurityCheck, setLastSecurityCheck] = useState(new Date().toLocaleString('zh-CN'));
  const [isScanning, setIsScanning] = useState(false);

  useEffect(() => {
    // 模拟安全设置数据
    const mockSettings: SecuritySetting[] = [
      {
        id: 'two-factor',
        name: '两步验证',
        description: '使用手机验证码或安全密钥进行登录验证',
        status: 'disabled',
        action: '启用'
      },
      {
        id: 'app-password',
        name: '应用专用密码',
        description: '为第三方应用生成专用密码，提高账户安全性',
        status: 'disabled',
        action: '管理'
      },
      {
        id: 'login-alert',
        name: '登录提醒',
        description: '当有新设备登录时，通过短信或邮件通知',
        status: 'enabled',
        action: '管理'
      },
      {
        id: 'device-management',
        name: '设备管理',
        description: '查看和管理已登录的设备',
        status: 'enabled',
        action: '查看'
      },
      {
        id: 'password-expiry',
        name: '密码过期提醒',
        description: '定期提醒更换密码，提高账户安全性',
        status: 'enabled',
        action: '设置'
      },
      {
        id: 'suspicious-login',
        name: '可疑登录保护',
        description: '自动检测并阻止可疑的登录尝试',
        status: 'enabled',
        action: '管理'
      }
    ];

    setSecuritySettings(mockSettings);
  }, []);

  const getSecurityStatusBadge = (status: string) => {
    switch (status) {
      case 'enabled':
        return (
          <span className="security-badge security-badge-safe">
            <CheckCircle className="h-4 w-4 mr-1" />
            已启用
          </span>
        );
      case 'disabled':
        return (
          <span className="security-badge security-badge-warning">
            <AlertTriangle className="h-4 w-4 mr-1" />
            未启用
          </span>
        );
      case 'warning':
        return (
          <span className="security-badge security-badge-danger">
            <AlertTriangle className="h-4 w-4 mr-1" />
            需要注意
          </span>
        );
      default:
        return null;
    }
  };

  const getPasswordStrengthIndicator = () => {
    switch (passwordStrength) {
      case 'weak':
        return (
          <div className="flex items-center">
            <div className="w-24 bg-gray-200 rounded-full h-2.5">
              <div className="bg-red-500 h-2.5 rounded-full w-1/3"></div>
            </div>
            <span className="ml-2 text-sm font-medium text-red-600">弱</span>
          </div>
        );
      case 'medium':
        return (
          <div className="flex items-center">
            <div className="w-24 bg-gray-200 rounded-full h-2.5">
              <div className="bg-yellow-500 h-2.5 rounded-full w-2/3"></div>
            </div>
            <span className="ml-2 text-sm font-medium text-yellow-600">中等</span>
          </div>
        );
      case 'strong':
        return (
          <div className="flex items-center">
            <div className="w-24 bg-gray-200 rounded-full h-2.5">
              <div className="bg-green-500 h-2.5 rounded-full w-full"></div>
            </div>
            <span className="ml-2 text-sm font-medium text-green-600">强</span>
          </div>
        );
      default:
        return null;
    }
  };

  const handleSecurityAction = (settingId: string) => {
    // 模拟处理安全设置操作
    console.log(`Performing action for setting: ${settingId}`);
    
    // 切换两步验证状态的示例
    if (settingId === 'two-factor') {
      setSecuritySettings(prevSettings => 
        prevSettings.map(setting => 
          setting.id === settingId 
            ? { 
                ...setting, 
                status: setting.status === 'enabled' ? 'disabled' : 'enabled',
                action: setting.status === 'enabled' ? '启用' : '禁用'
              }
            : setting
        )
      );
      
      // 更新安全评分
      setSecurityScore(prevScore => 
        settingId === 'two-factor' ? prevScore + 15 : prevScore
      );
    }
  };

  const runSecurityScan = async () => {
    setIsScanning(true);
    
    // 模拟安全扫描过程
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    setLastSecurityCheck(new Date().toLocaleString('zh-CN'));
    setIsScanning(false);
    
    // 模拟扫描结果
    alert('安全扫描完成！未发现严重安全问题。');
  };

  const getSecurityScoreColor = () => {
    if (securityScore >= 80) return 'text-green-600';
    if (securityScore >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="space-y-8">
      {/* 安全评分卡片 */}
      <div className="bg-gradient-to-r from-primary-600 to-primary-800 rounded-lg shadow-lg p-6 text-white">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-2xl font-bold">安全设置</h1>
            <p className="mt-2 text-primary-100">
              管理您的QQ邮箱安全设置，保护您的账户安全
            </p>
          </div>
          <div className="mt-4 md:mt-0 flex items-center">
            <div className="text-center">
              <div className="text-4xl font-bold {getSecurityScoreColor()}">{securityScore}</div>
              <div className="text-sm text-primary-100">安全评分</div>
            </div>
            <div className="ml-6">
              <button
                onClick={runSecurityScan}
                disabled={isScanning}
                className="btn bg-white text-primary-700 hover:bg-primary-50 flex items-center"
              >
                {isScanning ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-1 animate-spin" />
                    扫描中...
                  </>
                ) : (
                  <>
                    <Shield className="h-4 w-4 mr-1" />
                    安全扫描
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
        <div className="mt-6 flex flex-wrap gap-4">
          <div className="flex items-center text-primary-100">
            <Clock className="h-4 w-4 mr-1" />
            上次安全检查: {lastSecurityCheck}
          </div>
        </div>
      </div>

      {/* 安全设置列表 */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 flex items-center">
            <Shield className="h-5 w-5 mr-2" />
            账户安全设置
          </h2>
        </div>
        <div className="divide-y divide-gray-200">
          {securitySettings.map((setting) => (
            <div key={setting.id} className="p-6 flex items-center justify-between">
              <div className="flex-1">
                <h3 className="text-sm font-medium text-gray-900">{setting.name}</h3>
                <p className="mt-1 text-sm text-gray-600">{setting.description}</p>
              </div>
              <div className="flex items-center space-x-4">
                <div>
                  {getSecurityStatusBadge(setting.status)}
                </div>
                <button
                  onClick={() => handleSecurityAction(setting.id)}
                  className="btn btn-secondary flex items-center text-sm"
                >
                  {setting.action}
                  <ChevronRight className="h-4 w-4 ml-1" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 密码管理 */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 flex items-center">
            <Key className="h-5 w-5 mr-2" />
            密码管理
          </h2>
        </div>
        <div className="p-6 space-y-6">
          <div>
            <div className="flex items-center justify-between mb-2">
              <label htmlFor="current-password" className="text-sm font-medium text-gray-700">
                当前密码
              </label>
            </div>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                id="current-password"
                className="input"
                placeholder="请输入当前密码"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                {showPassword ? (
                  <EyeOff className="h-5 w-5 text-gray-400" />
                ) : (
                  <Eye className="h-5 w-5 text-gray-400" />
                )}
              </button>
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <label htmlFor="new-password" className="text-sm font-medium text-gray-700">
                新密码
              </label>
              {getPasswordStrengthIndicator()}
            </div>
            <input
              type={showPassword ? 'text' : 'password'}
              id="new-password"
              className="input"
              placeholder="请输入新密码"
            />
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <label htmlFor="confirm-password" className="text-sm font-medium text-gray-700">
                确认新密码
              </label>
            </div>
            <input
              type={showPassword ? 'text' : 'password'}
              id="confirm-password"
              className="input"
              placeholder="请再次输入新密码"
            />
          </div>

          <div className="pt-4">
            <button className="btn btn-primary w-full">
              更改密码
            </button>
          </div>

          <div className="mt-6 pt-6 border-t border-gray-200">
            <h3 className="text-sm font-medium text-gray-900 mb-4">密码安全建议</h3>
            <div className="space-y-3">
              <div className="flex items-start">
                <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
                <p className="text-sm text-gray-600">
                  使用至少8个字符的密码，包含字母、数字和特殊字符
                </p>
              </div>
              <div className="flex items-start">
                <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
                <p className="text-sm text-gray-600">
                  不要使用与其他网站相同的密码
                </p>
              </div>
              <div className="flex items-start">
                <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
                <p className="text-sm text-gray-600">
                  定期更换密码，建议每3-6个月更换一次
                </p>
              </div>
              <div className="flex items-start">
                <AlertTriangle className="h-5 w-5 text-yellow-500 mr-2 mt-0.5" />
                <p className="text-sm text-gray-600">
                  不要在公共场合或不安全的网络环境下输入密码
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 设备管理 */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 flex items-center">
            <Smartphone className="h-5 w-5 mr-2" />
            设备管理
          </h2>
        </div>
        <div className="p-6">
          <div className="space-y-4">
            <div className="p-4 bg-gray-50 rounded-md">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-sm font-medium text-gray-900">Windows 10 - Chrome</h3>
                  <p className="mt-1 text-sm text-gray-600">
                    上次登录: 2026-01-28 14:30
                  </p>
                  <p className="mt-1 text-xs text-gray-500">
                    IP地址: 192.168.1.100
                  </p>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="security-badge security-badge-safe">
                    <CheckCircle className="h-3 w-3 mr-1" />
                    可信
                  </span>
                  <button className="text-sm text-primary-600 hover:text-primary-500">
                    移除
                  </button>
                </div>
              </div>
            </div>
            
            <div className="p-4 bg-yellow-50 rounded-md">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-sm font-medium text-gray-900">MacOS - Safari</h3>
                  <p className="mt-1 text-sm text-gray-600">
                    上次登录: 2026-01-27 10:15
                  </p>
                  <p className="mt-1 text-xs text-gray-500">
                    IP地址: 203.195.134.56
                  </p>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="security-badge security-badge-warning">
                    <AlertTriangle className="h-3 w-3 mr-1" />
                    新设备
                  </span>
                  <button className="text-sm text-primary-600 hover:text-primary-500">
                    验证
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <div className="mt-6 text-center">
            <button className="btn btn-secondary">
              查看所有设备
            </button>
          </div>
        </div>
      </div>

      {/* 安全建议 */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 flex items-center">
            <AlertTriangle className="h-5 w-5 mr-2" />
            安全建议
          </h2>
        </div>
        <div className="p-6">
          <div className="space-y-4">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <div className="p-2 bg-blue-100 rounded-full">
                  <Lock className="h-5 w-5 text-blue-600" />
                </div>
              </div>
              <div className="ml-4">
                <h3 className="text-sm font-medium text-gray-900">启用两步验证</h3>
                <p className="mt-1 text-sm text-gray-600">
                  两步验证可以大大提高您的账户安全性，即使密码被泄露，攻击者也无法登录您的账户。
                </p>
                <button
                  onClick={() => handleSecurityAction('two-factor')}
                  className="mt-2 text-sm text-primary-600 hover:text-primary-500"
                >
                  立即启用
                </button>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <div className="p-2 bg-green-100 rounded-full">
                  <Key className="h-5 w-5 text-green-600" />
                </div>
              </div>
              <div className="ml-4">
                <h3 className="text-sm font-medium text-gray-900">更新密码</h3>
                <p className="mt-1 text-sm text-gray-600">
                  您的密码已经使用了超过3个月，建议更新密码以提高账户安全性。
                </p>
                <button className="mt-2 text-sm text-primary-600 hover:text-primary-500">
                  立即更新
                </button>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <div className="p-2 bg-yellow-100 rounded-full">
                  <Smartphone className="h-5 w-5 text-yellow-600" />
                </div>
              </div>
              <div className="ml-4">
                <h3 className="text-sm font-medium text-gray-900">管理可信设备</h3>
                <p className="mt-1 text-sm text-gray-600">
                  定期查看并管理您的可信设备，移除不再使用的设备，防止未授权访问。
                </p>
                <button className="mt-2 text-sm text-primary-600 hover:text-primary-500">
                  查看设备
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// 辅助组件
const Clock = ({ className }: { className?: string }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
    className={className}
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    />
  </svg>
);

export default SecuritySettings;