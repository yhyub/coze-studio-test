import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Home from './pages/Home';
import MailList from './pages/MailList';
import MailDetail from './pages/MailDetail';
import SecuritySettings from './pages/SecuritySettings';
import Login from './pages/Login';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [userInfo, setUserInfo] = useState(null);

  const handleLogin = (userData) => {
    setUserInfo(userData);
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    setUserInfo(null);
    setIsAuthenticated(false);
  };

  return (
    <Router>
      <Routes>
        <Route 
          path="/login" 
          element={
            isAuthenticated ? (
              <Navigate to="/" replace />
            ) : (
              <Login onLogin={handleLogin} />
            )
          } 
        />
        <Route 
          path="/" 
          element={
            isAuthenticated ? (
              <Layout userInfo={userInfo} onLogout={handleLogout}>
                <Home />
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          } 
        />
        <Route 
          path="/mail/list" 
          element={
            isAuthenticated ? (
              <Layout userInfo={userInfo} onLogout={handleLogout}>
                <MailList />
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          } 
        />
        <Route 
          path="/mail/detail/:id" 
          element={
            isAuthenticated ? (
              <Layout userInfo={userInfo} onLogout={handleLogout}>
                <MailDetail />
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          } 
        />
        <Route 
          path="/security" 
          element={
            isAuthenticated ? (
              <Layout userInfo={userInfo} onLogout={handleLogout}>
                <SecuritySettings />
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          } 
        />
        <Route 
          path="*" 
          element={
            isAuthenticated ? (
              <Navigate to="/" replace />
            ) : (
              <Navigate to="/login" replace />
            )
          } 
        />
      </Routes>
    </Router>
  );
}

export default App;