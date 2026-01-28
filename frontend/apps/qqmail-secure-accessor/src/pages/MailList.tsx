import React, { useState, useEffect } from 'react';
import { Mail, Search, Filter, CheckCircle, AlertCircle, Star, Trash2, Archive, MoreVertical, ChevronDown, ChevronUp } from '@heroicons/react/24/outline';
import { Link } from 'react-router-dom';

interface Mail {
  id: number;
  subject: string;
  from: string;
  date: string;
  isUnread: boolean;
  isImportant: boolean;
  isStarred: boolean;
  size: string;
}

const MailList: React.FC = () => {
  const [mails, setMails] = useState<Mail[]>([]);
  const [filteredMails, setFilteredMails] = useState<Mail[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filter, setFilter] = useState('all');
  const [sortBy, setSortBy] = useState('date');
  const [isLoading, setIsLoading] = useState(true);

  // 模拟邮件数据
  useEffect(() => {
    const fetchMails = async () => {
      setIsLoading(true);
      // 模拟网络请求延迟
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const mockMails: Mail[] = [
        {
          id: 1,
          subject: '[yhyub/yhyub-yfdxg] Run failed: Data Fetch - master (6295919)',
          from: 'notifications@github.com',
          date: '2026-01-28 14:30',
          isUnread: true,
          isImportant: false,
          isStarred: false,
          size: '2 KB'
        },
        {
          id: 2,
          subject: '[yhyub/yhyub-yfdxg] CI activity',
          from: 'ci_activity@noreply.github.com',
          date: '2026-01-28 13:45',
          isUnread: true,
          isImportant: false,
          isStarred: false,
          size: '1.5 KB'
        },
        {
          id: 3,
          subject: 'QQ邮箱安全提醒',
          from: 'service@mail.qq.com',
          date: '2026-01-28 12:20',
          isUnread: false,
          isImportant: true,
          isStarred: true,
          size: '3 KB'
        },
        {
          id: 4,
          subject: 'GitHub Weekly Digest',
          from: 'noreply@github.com',
          date: '2026-01-28 10:15',
          isUnread: false,
          isImportant: false,
          isStarred: false,
          size: '5 KB'
        },
        {
          id: 5,
          subject: 'QQ邮箱团队祝您周末愉快',
          from: 'service@mail.qq.com',
          date: '2026-01-28 09:00',
          isUnread: false,
          isImportant: false,
          isStarred: false,
          size: '2.5 KB'
        },
        {
          id: 6,
          subject: '[yhyub/yhyub-yfdxg] Pull request #123: Update README.md',
          from: 'notifications@github.com',
          date: '2026-01-27 16:45',
          isUnread: false,
          isImportant: true,
          isStarred: true,
          size: '1.8 KB'
        },
        {
          id: 7,
          subject: '[yhyub/yhyub-yfdxg] Issue #456: Fix data fetching error',
          from: 'notifications@github.com',
          date: '2026-01-27 14:20',
          isUnread: false,
          isImportant: true,
          isStarred: false,
          size: '2.2 KB'
        },
        {
          id: 8,
          subject: 'GitHub Security Alert: Vulnerability in dependency',
          from: 'securityalerts@github.com',
          date: '2026-01-27 11:30',
          isUnread: false,
          isImportant: true,
          isStarred: true,
          size: '4 KB'
        }
      ];

      setMails(mockMails);
      setFilteredMails(mockMails);
      setIsLoading(false);
    };

    fetchMails();
  }, []);

  // 过滤和搜索邮件
  useEffect(() => {
    let result = [...mails];

    // 应用搜索
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(mail => 
        mail.subject.toLowerCase().includes(term) || 
        mail.from.toLowerCase().includes(term)
      );
    }

    // 应用过滤
    if (filter === 'unread') {
      result = result.filter(mail => mail.isUnread);
    } else if (filter === 'important') {
      result = result.filter(mail => mail.isImportant);
    } else if (filter === 'starred') {
      result = result.filter(mail => mail.isStarred);
    }

    // 应用排序
    if (sortBy === 'date') {
      result.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    } else if (sortBy === 'from') {
      result.sort((a, b) => a.from.localeCompare(b.from));
    } else if (sortBy === 'subject') {
      result.sort((a, b) => a.subject.localeCompare(b.subject));
    }

    setFilteredMails(result);
  }, [mails, searchTerm, filter, sortBy]);

  // 标记邮件为已读/未读
  const toggleReadStatus = (id: number) => {
    setMails(prevMails => 
      prevMails.map(mail => 
        mail.id === id ? { ...mail, isUnread: !mail.isUnread } : mail
      )
    );
  };

  // 标记邮件为重要/不重要
  const toggleImportantStatus = (id: number) => {
    setMails(prevMails => 
      prevMails.map(mail => 
        mail.id === id ? { ...mail, isImportant: !mail.isImportant } : mail
      )
    );
  };

  // 标记邮件为星标/取消星标
  const toggleStarStatus = (id: number) => {
    setMails(prevMails => 
      prevMails.map(mail => 
        mail.id === id ? { ...mail, isStarred: !mail.isStarred } : mail
      )
    );
  };

  return (
    <div className="space-y-6">
      {/* 页面标题和操作栏 */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
        <div className="flex items-center">
          <Mail className="h-6 w-6 text-primary-600 mr-2" />
          <h1 className="text-2xl font-bold text-gray-900">邮件列表</h1>
          <span className="ml-4 text-sm text-gray-500">
            共 {filteredMails.length} 封邮件
          </span>
        </div>
        <div className="flex items-center space-x-4">
          <div className="relative">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-gray-400" />
            </div>
            <input
              type="text"
              placeholder="搜索邮件"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10 w-full md:w-64"
            />
          </div>
          <div className="flex items-center space-x-2">
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="input text-sm"
            >
              <option value="all">全部</option>
              <option value="unread">未读</option>
              <option value="important">重要</option>
              <option value="starred">星标</option>
            </select>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="input text-sm"
            >
              <option value="date">按日期</option>
              <option value="from">按发件人</option>
              <option value="subject">按主题</option>
            </select>
          </div>
        </div>
      </div>

      {/* 邮件列表 */}
      <div className="card">
        {isLoading ? (
          <div className="p-8 text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">加载邮件中...</p>
          </div>
        ) : filteredMails.length === 0 ? (
          <div className="p-8 text-center">
            <Mail className="h-12 w-12 text-gray-300 mx-auto" />
            <p className="mt-4 text-gray-600">没有找到邮件</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {filteredMails.map((mail) => (
              <div
                key={mail.id}
                className={`flex items-center p-4 hover:bg-gray-50 ${mail.isUnread ? 'bg-blue-50' : ''}`}
              >
                <div className="flex-shrink-0 space-y-2 mr-4">
                  <button
                    onClick={() => toggleReadStatus(mail.id)}
                    className="p-1 text-gray-400 hover:text-primary-600"
                    aria-label={mail.isUnread ? '标记为已读' : '标记为未读'}
                  >
                    {mail.isUnread ? (
                      <CheckCircle className="h-5 w-5" />
                    ) : (
                      <CheckCircle className="h-5 w-5" />
                    )}
                  </button>
                  <button
                    onClick={() => toggleImportantStatus(mail.id)}
                    className={`p-1 ${mail.isImportant ? 'text-yellow-500' : 'text-gray-400 hover:text-yellow-500'}`}
                    aria-label={mail.isImportant ? '取消重要标记' : '标记为重要'}
                  >
                    <AlertCircle className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => toggleStarStatus(mail.id)}
                    className={`p-1 ${mail.isStarred ? 'text-yellow-500' : 'text-gray-400 hover:text-yellow-500'}`}
                    aria-label={mail.isStarred ? '取消星标' : '标记为星标'}
                  >
                    <Star className="h-5 w-5" />
                  </button>
                </div>
                <div className="flex-1 min-w-0">
                  <Link to={`/mail/detail/${mail.id}`} className="block hover:bg-gray-100 p-2 rounded-md">
                    <div className="flex items-start justify-between">
                      <h3 className={`text-sm font-medium ${mail.isUnread ? 'text-gray-900' : 'text-gray-600'}`}>
                        {mail.subject}
                      </h3>
                      <div className="flex items-center space-x-4">
                        <span className="text-xs text-gray-500 whitespace-nowrap">{mail.date}</span>
                        <span className="text-xs text-gray-500 whitespace-nowrap">{mail.size}</span>
                      </div>
                    </div>
                    <div className="mt-1 text-sm text-gray-500">
                      发件人: {mail.from}
                    </div>
                  </Link>
                </div>
                <div className="flex-shrink-0 ml-4">
                  <div className="flex items-center space-x-2">
                    <button className="p-1 text-gray-400 hover:text-gray-600" aria-label="存档">
                      <Archive className="h-5 w-5" />
                    </button>
                    <button className="p-1 text-gray-400 hover:text-red-600" aria-label="删除">
                      <Trash2 className="h-5 w-5" />
                    </button>
                    <button className="p-1 text-gray-400 hover:text-gray-600" aria-label="更多操作">
                      <MoreVertical className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 分页控件 */}
      {!isLoading && filteredMails.length > 0 && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-600">
            显示 1 - {filteredMails.length} 封邮件，共 {mails.length} 封
          </div>
          <div className="flex items-center space-x-2">
            <button className="btn btn-secondary disabled:opacity-50 disabled:cursor-not-allowed" disabled>
              <ChevronUp className="h-4 w-4 mr-1" />
              上一页
            </button>
            <button className="btn btn-secondary disabled:opacity-50 disabled:cursor-not-allowed" disabled>
              下一页
              <ChevronDown className="h-4 w-4 ml-1" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default MailList;