import React from 'react'
import { Row, Col, Card, Statistic, Typography, Space, Button } from 'antd'
import { 
  ShoppingCartOutlined, 
  DollarOutlined, 
  ClockCircleOutlined,
  CheckCircleOutlined,
  RiseOutlined,
  ReloadOutlined
} from '@ant-design/icons'

const { Title } = Typography

const DashboardPage: React.FC = () => {
  // Mock data - will be replaced with real data from service
  const stats = {
    totalOrders: 156,
    pendingOrders: 8,
    completedOrders: 142,
    totalRevenue: 45280,
    avgOrderValue: 290,
    avgPreparationTime: 18
  }

  const recentOrders = [
    { id: 'DLZ-20250102-001', customer: 'John Doe', amount: 450, status: 'pending' },
    { id: 'DLZ-20250102-002', customer: 'Jane Smith', amount: 320, status: 'preparing' },
    { id: 'DLZ-20250102-003', customer: 'Mike Johnson', amount: 180, status: 'ready' },
  ]

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Title level={2} style={{ margin: 0 }}>
          Dashboard
        </Title>
        <Button icon={<ReloadOutlined />} onClick={() => window.location.reload()}>
          Refresh
        </Button>
      </div>

      {/* Stats Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Orders"
              value={stats.totalOrders}
              prefix={<ShoppingCartOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Pending Orders"
              value={stats.pendingOrders}
              prefix={<ClockCircleOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Completed Orders"
              value={stats.completedOrders}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Revenue"
              value={stats.totalRevenue}
              prefix={<DollarOutlined />}
              precision={0}
              valueStyle={{ color: '#52c41a' }}
              suffix="₹"
            />
          </Card>
        </Col>
      </Row>

      {/* Additional Stats */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12}>
          <Card>
            <Statistic
              title="Average Order Value"
              value={stats.avgOrderValue}
              prefix={<RiseOutlined />}
              precision={0}
              valueStyle={{ color: '#1890ff' }}
              suffix="₹"
            />
          </Card>
        </Col>
        <Col xs={24} sm={12}>
          <Card>
            <Statistic
              title="Avg. Preparation Time"
              value={stats.avgPreparationTime}
              prefix={<ClockCircleOutlined />}
              valueStyle={{ color: '#722ed1' }}
              suffix="min"
            />
          </Card>
        </Col>
      </Row>

      {/* Recent Orders */}
      <Card title="Recent Orders" style={{ marginBottom: 24 }}>
        <Space direction="vertical" style={{ width: '100%' }}>
          {recentOrders.map((order) => (
            <Card key={order.id} size="small" style={{ backgroundColor: '#fafafa' }}>
              <Row justify="space-between" align="middle">
                <Col>
                  <Space direction="vertical" size="small">
                    <strong>{order.id}</strong>
                    <span>{order.customer}</span>
                  </Space>
                </Col>
                <Col>
                  <Space direction="vertical" size="small" align="end">
                    <strong>₹{order.amount}</strong>
                    <span className={`status-${order.status}`} style={{ 
                      padding: '2px 8px', 
                      borderRadius: '4px',
                      fontSize: '12px',
                      textTransform: 'capitalize'
                    }}>
                      {order.status}
                    </span>
                  </Space>
                </Col>
              </Row>
            </Card>
          ))}
        </Space>
      </Card>

      {/* Quick Actions */}
      <Card title="Quick Actions">
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} md={6}>
            <Button type="primary" block size="large">
              View All Orders
            </Button>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Button block size="large">
              Manage Inventory
            </Button>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Button block size="large">
              Update Products
            </Button>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Button block size="large">
              View Reports
            </Button>
          </Col>
        </Row>
      </Card>
    </div>
  )
}

export default DashboardPage
