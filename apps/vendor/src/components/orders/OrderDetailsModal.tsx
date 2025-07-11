import React from 'react'
import {
  Modal,
  Descriptions,
  List,
  Image,
  Tag,
  Button,
  Space,
  Typography,
  Divider,
  Row,
  Col,
  Card,
  Avatar,
  Tooltip,
  Badge
} from 'antd'
import {
  UserOutlined,
  PhoneOutlined,
  EnvironmentOutlined,
  ClockCircleOutlined,
  ShoppingCartOutlined,
  DollarOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  LoadingOutlined
} from '@ant-design/icons'
import { Order, OrderStatus } from '@/types'
import dayjs from 'dayjs'

const { Title, Text } = Typography

interface OrderDetailsModalProps {
  order: Order | null
  visible: boolean
  onClose: () => void
  onStatusChange: (orderId: string, status: OrderStatus) => Promise<void>
  loading?: boolean
}

const OrderDetailsModal: React.FC<OrderDetailsModalProps> = ({
  order,
  visible,
  onClose,
  onStatusChange,
  loading = false
}) => {
  if (!order) return null

  const getStatusColor = (status: OrderStatus) => {
    switch (status) {
      case 'processing': return 'orange'
      case 'out_for_delivery': return 'blue'
      case 'delivered': return 'success'
      case 'cancelled': return 'red'
      default: return 'default'
    }
  }

  const getStatusIcon = (status: OrderStatus) => {
    switch (status) {
      case 'processing': return <LoadingOutlined spin />
      case 'out_for_delivery': return <CheckCircleOutlined />
      case 'delivered': return <CheckCircleOutlined />
      case 'cancelled': return <CloseCircleOutlined />
      default: return <ClockCircleOutlined />
    }
  }

  const handleStatusChange = async (newStatus: OrderStatus) => {
    try {
      await onStatusChange(order.id, newStatus)
    } catch (error) {
      console.error('Failed to update order status:', error)
    }
  }

  const getActionButtons = () => {
    const buttons = []

    switch (order.status) {
      case 'processing':
        buttons.push(
          <Button
            key="deliver"
            type="primary"
            icon={<CheckCircleOutlined />}
            onClick={() => handleStatusChange('out_for_delivery')}
            loading={loading}
          >
            Mark for Delivery
          </Button>,
          <Button
            key="cancel"
            danger
            icon={<CloseCircleOutlined />}
            onClick={() => handleStatusChange('cancelled')}
            loading={loading}
          >
            Cancel Order
          </Button>
        )
        break
    }
    
    return buttons
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount)
  }

  return (
    <Modal
      title={
        <Space>
          <ShoppingCartOutlined />
          <span>Order Details</span>
          <Tag 
            color={getStatusColor(order.status)} 
            icon={getStatusIcon(order.status)}
          >
            {order.status.toUpperCase()}
          </Tag>
        </Space>
      }
      open={visible}
      onCancel={onClose}
      width={800}
      footer={
        <Space>
          <Button onClick={onClose}>Close</Button>
          {getActionButtons()}
        </Space>
      }
    >
      <div style={{ maxHeight: '70vh', overflowY: 'auto' }}>
        {/* Order Summary */}
        <Card size="small" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={12}>
              <Descriptions size="small" column={1}>
                <Descriptions.Item label="Order Number">
                  <Text strong>{order.order_number}</Text>
                </Descriptions.Item>
                <Descriptions.Item label="Order Time">
                  {dayjs(order.created_at).format('DD/MM/YYYY hh:mm A')}
                </Descriptions.Item>
                <Descriptions.Item label="Total Amount">
                  <Text strong style={{ fontSize: '16px', color: '#1890ff' }}>
                    {formatCurrency(order.total_amount)}
                  </Text>
                </Descriptions.Item>
              </Descriptions>
            </Col>
            <Col span={12}>
              <Descriptions size="small" column={1}>
                <Descriptions.Item label="Payment Method">
                  <Tag color="blue">{order.payment_method}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Delivery Type">
                  <Tag color="green">{order.delivery_type}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Items Count">
                  <Badge count={order.order_items?.length || 0} showZero />
                </Descriptions.Item>
              </Descriptions>
            </Col>
          </Row>
        </Card>

        {/* Customer Information */}
        <Card 
          title={
            <Space>
              <UserOutlined />
              <span>Customer Information</span>
            </Space>
          }
          size="small" 
          style={{ marginBottom: 16 }}
        >
          <Descriptions size="small" column={2}>
            <Descriptions.Item label="Name">
              <Space>
                <Avatar size="small" icon={<UserOutlined />} />
                <Text>{order.users?.user_metadata?.name || 'Customer'}</Text>
              </Space>
            </Descriptions.Item>
            <Descriptions.Item label="Email">
              {order.users?.email}
            </Descriptions.Item>
            <Descriptions.Item label="Phone">
              <Space>
                <PhoneOutlined />
                <Text>{order.users?.user_metadata?.phone || 'Not provided'}</Text>
              </Space>
            </Descriptions.Item>
            <Descriptions.Item label="Address">
              <Space>
                <EnvironmentOutlined />
                <Text>{order.delivery_address}</Text>
              </Space>
            </Descriptions.Item>
          </Descriptions>
        </Card>

        {/* Order Items */}
        <Card 
          title={
            <Space>
              <ShoppingCartOutlined />
              <span>Order Items ({order.order_items?.length || 0})</span>
            </Space>
          }
          size="small"
        >
          <List
            dataSource={order.order_items || []}
            renderItem={(item) => (
              <List.Item>
                <List.Item.Meta
                  avatar={
                    <Image
                      width={50}
                      height={50}
                      src={item.image_url || '/placeholder-product.png'}
                      fallback="/placeholder-product.png"
                      style={{ borderRadius: 4 }}
                    />
                  }
                  title={
                    <Space>
                      <Text strong>{item.product_name}</Text>
                      <Tag color="blue">Qty: {item.quantity}</Tag>
                    </Space>
                  }
                  description={
                    <Space direction="vertical" size="small">
                      <Text type="secondary">
                        Unit Price: {formatCurrency(item.product_price)}
                      </Text>
                      {item.options && (
                        <Text type="secondary">
                          Options: {JSON.stringify(item.options)}
                        </Text>
                      )}
                    </Space>
                  }
                />
                <div>
                  <Text strong style={{ fontSize: '16px' }}>
                    {formatCurrency(item.total_price)}
                  </Text>
                </div>
              </List.Item>
            )}
          />
        </Card>

        {/* Order Timeline */}
        <Card 
          title={
            <Space>
              <ClockCircleOutlined />
              <span>Order Timeline</span>
            </Space>
          }
          size="small" 
          style={{ marginTop: 16 }}
        >
          <Descriptions size="small" column={1}>
            <Descriptions.Item label="Order Placed">
              {dayjs(order.created_at).format('DD/MM/YYYY hh:mm A')}
            </Descriptions.Item>
            {order.updated_at !== order.created_at && (
              <Descriptions.Item label="Last Updated">
                {dayjs(order.updated_at).format('DD/MM/YYYY hh:mm A')}
              </Descriptions.Item>
            )}
            {order.status === 'delivered' && order.delivered_at && (
              <Descriptions.Item label="Delivered At">
                {dayjs(order.delivered_at).format('DD/MM/YYYY hh:mm A')}
              </Descriptions.Item>
            )}
          </Descriptions>
        </Card>
      </div>
    </Modal>
  )
}

export default OrderDetailsModal
