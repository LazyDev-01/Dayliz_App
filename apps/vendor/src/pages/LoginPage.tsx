import React, { useState } from 'react'
import { Layout, Card, Form, Input, Button, Typography, Alert, Space } from 'antd'
import { UserOutlined, LockOutlined, ShopOutlined } from '@ant-design/icons'
import { useAuthStore } from '@/stores/authStore'
import type { LoginCredentials } from '@/types'

const { Content } = Layout
const { Title, Text } = Typography

const LoginPage: React.FC = () => {
  const [form] = Form.useForm()
  const { login, isLoading, error, clearError } = useAuthStore()
  const [, setLoginAttempted] = useState(false)

  const handleLogin = async (values: LoginCredentials) => {
    setLoginAttempted(true)
    clearError()
    
    const success = await login(values)
    if (!success) {
      setLoginAttempted(false)
    }
  }

  const handleFormChange = () => {
    if (error) {
      clearError()
    }
  }

  return (
    <Layout className="full-height" style={{ backgroundColor: '#f0f2f5' }}>
      <Content className="flex-center">
        <Card 
          style={{ 
            width: '100%', 
            maxWidth: 400, 
            margin: '0 16px',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)'
          }}
        >
          <div className="text-center" style={{ marginBottom: 32 }}>
            <ShopOutlined style={{ fontSize: 48, color: '#1890ff', marginBottom: 16 }} />
            <Title level={2} style={{ margin: 0, color: '#1890ff' }}>
              Dayliz Vendor Panel
            </Title>
            <Text type="secondary">
              Sign in to manage your store
            </Text>
          </div>

          {error && (
            <Alert
              message="Login Failed"
              description={error}
              type="error"
              showIcon
              closable
              onClose={clearError}
              style={{ marginBottom: 24 }}
            />
          )}

          <Form
            form={form}
            name="login"
            onFinish={handleLogin}
            onValuesChange={handleFormChange}
            layout="vertical"
            size="large"
          >
            <Form.Item
              name="email"
              label="Email"
              rules={[
                { required: true, message: 'Please enter your email' },
                { type: 'email', message: 'Please enter a valid email' }
              ]}
            >
              <Input
                prefix={<UserOutlined />}
                placeholder="Enter your email"
                autoComplete="email"
              />
            </Form.Item>

            <Form.Item
              name="password"
              label="Password"
              rules={[
                { required: true, message: 'Please enter your password' },
                { min: 6, message: 'Password must be at least 6 characters' }
              ]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder="Enter your password"
                autoComplete="current-password"
              />
            </Form.Item>

            <Form.Item style={{ marginBottom: 0 }}>
              <Button
                type="primary"
                htmlType="submit"
                loading={isLoading}
                block
                style={{ height: 48 }}
              >
                {isLoading ? 'Signing In...' : 'Sign In'}
              </Button>
            </Form.Item>
          </Form>

          <div className="text-center" style={{ marginTop: 24 }}>
            <Space direction="vertical" size="small">
              <Text type="secondary" style={{ fontSize: 12 }}>
                Having trouble signing in?
              </Text>
              <Text type="secondary" style={{ fontSize: 12 }}>
                Contact support for assistance
              </Text>
            </Space>
          </div>
        </Card>
      </Content>
    </Layout>
  )
}

export default LoginPage
