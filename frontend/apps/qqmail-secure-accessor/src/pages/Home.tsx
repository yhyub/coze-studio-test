import React, { useState, useEffect } from 'react';
import { Shield, Mail, AlertCircle, CheckCircle, Clock, Server, Lock, Globe } from '@heroicons/react/24/outline';

const Home: React.FC = () => {
  const [securityStatus, setSecurityStatus] = useState('safe');
  const [mailStats, setMailStats] = useState({
    total: 1256,
    unread: 45,
    important: 12,
    spam: 8
  });
  const [systemStatus, setSystemStatus] = useState({
    lastSync: new Date().toLocaleString('zh-CN'),
    connectionStatus: 'connected',
    serverTime: new Date().toLocaleTimeString('zh-CN')
  });
  const [recentMails, setRecentMails] = useState([
    {
      id: 1,
      subject: '[yhyub/yhyub-yfdxg] Run failed: Data Fetch - master (6295919)',
      from: 'notifications@github.com',
      date: '2026-01-28 14:30',
      isUnread: true,
      isImportant: false
    },
    {
      id: 2,
      subject: '[yhyub/yhyub-yfdxg] CI activity',
      from: 'ci_activity@noreply.github.com',
      date: '2026-01-28 13:45',
      isUnread: true,
      isImportant: false
    },
    {
      id: 3,
      subject: 'QQ邮箱安全提醒',
      from: 'service@mail.qq.com',
      date: '2026-01-28 12:20',
      isUnread: false,
      isImportant: true
    },
    {
      id: 4,
      subject: 'GitHub Weekly Digest',
      from: 'noreply@github.com',
      date: '2026-01-28 10:15',
      isUnread: false,
      isImportant: false
    },
    {
      id: 5,
      subject: 'QQ邮箱团队祝您周末愉快',
      from: 'service@mail.qq.com',
      date: '2026-01-28 09:00',
      isUnread: false,
      isImportant: false
    }
  ]);

  useEffect(() => {
    // 模拟实时更新服务器时间
    const interval = setInterval(() => {
      setSystemStatus(prev => ({
        ...prev,
        serverTime: new Date().toLocaleTimeString('zh-CN')
      }));
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  const getSecurityBadge = () => {
    switch (securityStatus) {
      case 'safe':
        return (
          <span className="security-badge security-badge-safe">
            <CheckCircle className="h-4 w-4 mr-1" />
            安全
          </span>
        );
      case 'warning':
        return (
          <span className="security-badge security-badge-warning">
            <AlertCircle className="h-4 w-4 mr-1" />
            警告
          </span>
        );
      case 'danger':
        return (
          <span className="security-badge security-badge-danger">
            <Lock className="h-4 w-4 mr-1" />
            危险
          </span>
        );
      default:
        return null;
    }
  };

  const getConnectionStatus = () => {
    switch (systemStatus.connectionStatus) {
      case 'connected':
        return (
          <span className="flex items-center text-green-600">
            <CheckCircle className="h-4 w-4 mr-1" />
            已连接
          </span>
        );
      case 'disconnected':
        return (
          <span className="flex items-center text-red-600">
            <AlertCircle className="h-4 w-4 mr-1" />
            未连接
          </span>
        );
      case 'connecting':
        return (
          <span className="flex items-center text-yellow-600">
            <Clock className="h-4 w-4 mr-1" />
            连接中
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="space-y-8">
      {/* 欢迎区域 */}
      <div className="bg-gradient-to-r from-primary-600 to-primary-800 rounded-lg shadow-lg p-6 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">欢迎使用QQ邮箱安全访问器</h1>
            <p className="mt-2 text-primary-100">
              安全访问和管理您的QQ邮箱，保护您的邮件数据
            </p>
          </div>
          <Shield className="h-16 w-16 text-white opacity-80" />
        </div>
        <div className="mt-6 flex flex-wrap gap-4">
          <div className="flex items-center">
            {getSecurityBadge()}
          </div>
          <div className="flex items-center text-primary-100">
            <Clock className="h-4 w-4 mr-1" />
            上次同步: {systemStatus.lastSync}
          </div>
          <div className="flex items-center text-primary-100">
            {getConnectionStatus()}
          </div>
        </div>
      </div>

      {/* 邮件统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">总邮件数</p>
              <p className="mt-1 text-2xl font-bold text-gray-900">{mailStats.total}</p>
            </div>
            <div className="p-3 rounded-full bg-blue-100">
              <Mail className="h-6 w-6 text-blue-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">未读邮件</p>
              <p className="mt-1 text-2xl font-bold text-gray-900">{mailStats.unread}</p>
            </div>
            <div className="p-3 rounded-full bg-green-100">
              <AlertCircle className="h-6 w-6 text-green-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">重要邮件</p>
              <p className="mt-1 text-2xl font-bold text-gray-900">{mailStats.important}</p>
            </div>
            <div className="p-3 rounded-full bg-yellow-100">
              <Shield className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">垃圾邮件</p>
              <p className="mt-1 text-2xl font-bold text-gray-900">{mailStats.spam}</p>
            </div>
            <div className="p-3 rounded-full bg-red-100">
              <AlertCircle className="h-6 w-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      {/* 最近邮件 */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 flex items-center">
            <Mail className="h-5 w-5 mr-2" />
            最近邮件
          </h2>
        </div>
        <div className="px-6 py-4">
          <div className="space-y-3">
            {recentMails.map((mail) => (
              <div
                key={mail.id}
                className={`p-4 rounded-md ${mail.isUnread ? 'bg-blue-50 border-l-4 border-blue-500' : 'bg-white hover:bg-gray-50'}`}
              >
                <div className="flex items-start justify-between">
                  <h3 className="text-sm font-medium text-gray-900 line-clamp-1">
                    {mail.subject}
                  </h3>
                  <span className="text-xs text-gray-500">{mail.date}</span>
                </div>
                <div className="mt-1 flex items-center">
                  <span className="text-sm text-gray-600">发件人: {mail.from}</span>
                  {mail.isImportant && (
                    <span className="ml-2 security-badge security-badge-warning">
                      <Shield className="h-3 w-3 mr-1" />
                      重要
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 text-center">
            <a
              href="/mail/list"
              className="inline-flex items-center text-sm font-medium text-primary-600 hover:text-primary-500"
            >
              查看更多邮件
              <svg
                className="ml-1 h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 8l4 4m0 0l-4 4m4-4H3"
                />
              </svg>
            </a>
          </div>
        </div>
      </div>

      {/* 系统状态 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="card p-6">
          <div className="flex items-center mb-4">
            <Server className="h-5 w-5 mr-2 text-gray-600" />
            <h2 className="text-lg font-medium text-gray-900">系统状态</h2>
          </div>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">服务器时间</span>
              <span className="text-sm font-medium text-gray-900">{systemStatus.serverTime}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">连接状态</span>
              {getConnectionStatus()}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">安全状态</span>
              {getSecurityBadge()}
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-center mb-4">
            <Globe className="h-5 w-5 mr-2 text-gray-600" />
            <h2 className="text-lg font-medium text-gray-900">安全建议</h2>
          </div>
          <div className="space-y-3">
            <div className="flex items-start">
              <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
              <p className="text-sm text-gray-600">
                使用强密码并定期更换
              </p>
            </div>
            <div className="flex items-start">
              <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
              <p className="text-sm text-gray-600">
                启用两步验证保护您的账号
              </p>
            </div>
            <div className="flex items-start">
              <CheckCircle className="h-5 w-5 text-green-500 mr-2 mt-0.5" />
              <p className="text-sm text-gray-600">
                定期检查并清理垃圾邮件
              </p>
            </div>
            <div className="flex items-start">
              <AlertCircle className="h-5 w-5 text-yellow-500 mr-2 mt-0.5" />
              <p className="text-sm text-gray-600">
                不要点击来自未知发件人的可疑链接
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;