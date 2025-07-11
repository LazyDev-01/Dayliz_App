import React, { useState, useEffect } from 'react'
import { Card, Typography, Button, Space, Table, Tag, Spin, message, Modal, Descriptions, Badge } from 'antd'
import { ReloadOutlined, SoundOutlined, EyeOutlined } from '@ant-design/icons'
import { useAuthStore } from '@/stores/authStore'
import { supabase } from '@/services/supabase'

const { Title } = Typography

// Order status configuration
const statusConfig = {
  processing: { color: 'orange', label: 'Processing' },
  out_for_delivery: { color: 'blue', label: 'Out for Delivery' },
  delivered: { color: 'success', label: 'Delivered' },
  cancelled: { color: 'error', label: 'Cancelled' }
}

export default function Orders() {
  const { vendor } = useAuthStore()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedOrder, setSelectedOrder] = useState(null)
  const [detailsVisible, setDetailsVisible] = useState(false)

  // Fetch orders from Supabase
  const fetchOrders = async () => {
    if (!vendor?.id) return

    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            product_name,
            quantity,
            product_price,
            total_price
          ),
          users!orders_user_id_fkey (
            id,
            email,
            user_metadata
          )
        `)
        .eq('assigned_vendor_id', vendor.id)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching orders:', error)
        message.error('Failed to load orders')
        return
      }

      setOrders(data || [])
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to load orders')
    } finally {
      setLoading(false)
    }
  }

  // Update order status
  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', orderId)

      if (error) {
        console.error('Error updating order:', error)
        message.error('Failed to update order status')
        return
      }

      message.success(`Order status updated to ${statusConfig[newStatus]?.label}`)
      fetchOrders() // Refresh orders
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to update order status')
    }
  }

  // Setup real-time subscription
  useEffect(() => {
    fetchOrders()

    if (!vendor?.id) return

    // Subscribe to real-time changes
    const channel = supabase
      .channel(`vendor-${vendor.id}-orders`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'orders',
        filter: `assigned_vendor_id=eq.${vendor.id}`
      }, (payload) => {
        console.log('Real-time order update:', payload)
        fetchOrders() // Refresh orders on any change

        // Play notification sound for new orders
        if (payload.eventType === 'INSERT') {
          const audio = new Audio('/notification.mp3')
          audio.play().catch(e => console.log('Audio play failed:', e))
          message.info('🔔 New order received!')
        }
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [vendor?.id])

  // Table columns
  const columns = [
    {
      title: 'Order ID',
      dataIndex: 'order_number',
      key: 'order_number',
      render: (orderNumber) => <strong>{orderNumber || 'N/A'}</strong>
    },
    {
      title: 'Customer',
      dataIndex: ['users', 'user_metadata', 'name'],
      key: 'customer',
      render: (name, record) => name || record.users?.email || 'Unknown'
    },
    {
      title: 'Items',
      dataIndex: 'order_items',
      key: 'items',
      render: (items) => items?.length || 0
    },
    {
      title: 'Total',
      dataIndex: 'total_amount',
      key: 'total',
      render: (amount) => `₹${amount?.toFixed(2) || '0.00'}`
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status) => (
        <Tag color={statusConfig[status]?.color || 'default'}>
          {statusConfig[status]?.label || status}
        </Tag>
      )
    },
    {
      title: 'Time',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (time) => new Date(time).toLocaleString()
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            size="small"
            icon={<EyeOutlined />}
            onClick={() => {
              setSelectedOrder(record)
              setDetailsVisible(true)
            }}
          >
            View
          </Button>
          {record.status === 'processing' && (
            <Button
              size="small"
              type="primary"
              onClick={() => updateOrderStatus(record.id, 'out_for_delivery')}
            >
              Mark for Delivery
            </Button>
          )}
        </Space>
      )
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <Title level={2}>📦 Orders Management</Title>
          <Space>
            <Button
              icon={<SoundOutlined />}
              onClick={() => {
                const audio = new Audio('/notification.mp3')
                audio.play().catch(e => console.log('Audio test failed:', e))
              }}
            >
              Test Sound
            </Button>
            <Button
              type="primary"
              icon={<ReloadOutlined />}
              onClick={fetchOrders}
              loading={loading}
            >
              Refresh
            </Button>
          </Space>
        </div>

        <div style={{ marginBottom: '16px' }}>
          <Space>
            <Badge count={orders.filter(o => o.status === 'processing').length} showZero>
              <Tag color="orange">Processing Orders</Tag>
            </Badge>
            <Badge count={orders.filter(o => o.status === 'out_for_delivery').length} showZero>
              <Tag color="blue">Out for Delivery</Tag>
            </Badge>
            <Badge count={orders.filter(o => o.status === 'delivered').length} showZero>
              <Tag color="green">Delivered</Tag>
            </Badge>
          </Space>
        </div>

        <Table
          columns={columns}
          dataSource={orders}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `Total ${total} orders`
          }}
          scroll={{ x: 800 }}
        />
      </Card>

      {/* Order Details Modal */}
      <Modal
        title={`Order Details - ${selectedOrder?.order_number || 'N/A'}`}
        open={detailsVisible}
        onCancel={() => setDetailsVisible(false)}
        footer={null}
        width={800}
      >
        {selectedOrder && (
          <div>
            <Descriptions bordered column={2}>
              <Descriptions.Item label="Order ID">{selectedOrder.order_number}</Descriptions.Item>
              <Descriptions.Item label="Status">
                <Tag color={statusConfig[selectedOrder.status]?.color}>
                  {statusConfig[selectedOrder.status]?.label}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Customer">
                {selectedOrder.users?.user_metadata?.name || selectedOrder.users?.email || 'Unknown'}
              </Descriptions.Item>
              <Descriptions.Item label="Total Amount">₹{selectedOrder.total_amount?.toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="Created At">
                {new Date(selectedOrder.created_at).toLocaleString()}
              </Descriptions.Item>
              <Descriptions.Item label="Payment Method">{selectedOrder.payment_method || 'N/A'}</Descriptions.Item>
            </Descriptions>

            <Title level={4} style={{ marginTop: '16px' }}>Order Items</Title>
            <Table
              dataSource={selectedOrder.order_items || []}
              rowKey="id"
              pagination={false}
              size="small"
              columns={[
                { title: 'Product', dataIndex: 'product_name', key: 'product_name' },
                { title: 'Quantity', dataIndex: 'quantity', key: 'quantity' },
                { title: 'Price', dataIndex: 'product_price', key: 'product_price', render: (price) => `₹${price}` },
                { title: 'Total', dataIndex: 'total_price', key: 'total_price', render: (total) => `₹${total}` }
              ]}
            />
          </div>
        )}
      </Modal>
    </div>
  )
}
