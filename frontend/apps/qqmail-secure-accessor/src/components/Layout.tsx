import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  Mail, 
  Shield, 
  Home, 
  LogOut, 
  User, 
  ChevronRight,
  Menu,
  X
} from '@heroicons/react/24/outline';

interface LayoutProps {
  children: React.ReactNode;
  userInfo: any;
  onLogout: () => void;
}

const Layout: React.FC<LayoutProps> = ({ children, userInfo, onLogout }) => {
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);

  const navItems = [
    { name: '首页', href: '/', icon: Home },
    { name: '邮件列表', href: '/mail/list', icon: Mail },
    { name: '安全设置', href: '/security', icon: Shield },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 顶部导航栏 */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0 flex items-center">
                <Shield className="h-8 w-8 text-primary-600" />
                <span className="ml-2 text-xl font-bold text-gray-900">QQ邮箱安全访问器</span>
              </div>
              <div className="hidden md:block">
                <div className="ml-10 flex items-center space-x-4">
                  {navItems.map((item) => {
                    const Icon = item.icon;
                    return (
                      <Link
                        key={item.name}
                        to={item.href}
                        className={`${
                          location.pathname === item.href
                            ? 'bg-primary-100 text-primary-700'
                            : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                        } px-3 py-2 rounded-md text-sm font-medium flex items-center`}
                      >
                        <Icon className="h-5 w-5 mr-2" />
                        {item.name}
                      </Link>
                    );
                  })}
                </div>
              </div>
            </div>
            <div className="flex items-center">
              <div className="hidden md:block">
                <div className="ml-4 flex items-center md:ml-6">
                  <div className="flex-shrink-0">
                    <button
                      onClick={onLogout}
                      className="p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                    >
                      <span className="sr-only">退出登录</span>
                      <LogOut className="h-6 w-6" />
                    </button>
                  </div>
                  <div className="ml-3 relative">
                    <div>
                      <button
                        type="button"
                        className="max-w-xs bg-white flex items-center text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                        id="user-menu-button"
                      >
                        <span className="sr-only">打开用户菜单</span>
                        <User className="h-8 w-8 rounded-full bg-gray-300" />
                        <span className="ml-2 text-sm font-medium text-gray-700">
                          {userInfo?.username || '用户'}
                        </span>
                        <ChevronRight className="h-4 w-4 ml-1" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <div className="md:hidden">
                <button
                  type="button"
                  className="bg-gray-100 rounded-md p-2 inline-flex items-center justify-center text-gray-500 hover:text-gray-600 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  aria-expanded="false"
                  onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                >
                  <span className="sr-only">打开菜单</span>
                  {mobileMenuOpen ? (
                    <X className="h-6 w-6" />
                  ) : (
                    <Menu className="h-6 w-6" />
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* 移动端菜单 */}
        {mobileMenuOpen && (
          <div className="md:hidden">
            <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    className={`${
                      location.pathname === item.href
                        ? 'bg-primary-100 text-primary-700'
                        : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                    } block px-3 py-2 rounded-md text-base font-medium flex items-center`}
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    <Icon className="h-5 w-5 mr-2" />
                    {item.name}
                  </Link>
                );
              })}
            </div>
            <div className="pt-4 pb-3 border-t border-gray-200">
              <div className="flex items-center px-5">
                <User className="h-8 w-8 rounded-full bg-gray-300" />
                <div className="ml-3">
                  <div className="text-base font-medium leading-none text-gray-800">
                    {userInfo?.username || '用户'}
                  </div>
                </div>
              </div>
              <div className="mt-3 px-2 space-y-1">
                <button
                  onClick={onLogout}
                  className="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-gray-900 hover:bg-gray-100 w-full text-left flex items-center"
                >
                  <LogOut className="h-5 w-5 mr-2" />
                  退出登录
                </button>
              </div>
            </div>
          </div>
        )}
      </header>

      {/* 主内容区域 */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>

      {/* 页脚 */}
      <footer className="bg-white border-t border-gray-200 mt-auto">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div className="flex justify-center items-center">
            <Shield className="h-6 w-6 text-primary-600" />
            <span className="ml-2 text-sm text-gray-500">
              QQ邮箱安全访问器 &copy; {new Date().getFullYear()}
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Layout;