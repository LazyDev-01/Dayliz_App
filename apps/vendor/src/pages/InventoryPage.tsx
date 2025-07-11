import React, { useState, useEffect } from 'react'
import { Card, Typography, Button, Space, Table, Tag, Progress, message } from 'antd'
import { ReloadOutlined, WarningOutlined } from '@ant-design/icons'
import { useAuthStore } from '@/stores/authStore'
import { supabase } from '@/services/supabase'

const { Title } = Typography

export default function InventoryPage() {
  const { vendor } = useAuthStore()
  const [inventory, setInventory] = useState([])
  const [loading, setLoading] = useState(true)

  // Fetch inventory data
  const fetchInventory = async () => {
    if (!vendor?.id) return

    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('products')
        .select(`
          id,
          name,
          stock_quantity,
          price,
          is_available,
          categories (
            name
          )
        `)
        .eq('vendor_id', vendor.id)
        .order('stock_quantity', { ascending: true })

      if (error) {
        console.error('Error fetching inventory:', error)
        message.error('Failed to load inventory')
        return
      }

      setInventory(data || [])
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to load inventory')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchInventory()
  }, [vendor?.id])

  // Calculate stock status
  const getStockStatus = (current) => {
    if (current === 0) return { status: 'Out of Stock', color: 'red', percent: 0 }
    if (current <= 5) return { status: 'Low Stock', color: 'orange', percent: 25 }
    if (current >= 100) return { status: 'Overstock', color: 'blue', percent: 100 }
    return { status: 'Normal', color: 'green', percent: 75 }
  }

  // Table columns
  const columns = [
    {
      title: 'Product Name',
      dataIndex: 'name',
      key: 'name',
      render: (name) => <strong>{name}</strong>
    },
    {
      title: 'Category',
      dataIndex: ['categories', 'name'],
      key: 'category',
      render: (categoryName) => categoryName || 'Uncategorized'
    },
    {
      title: 'Current Stock',
      dataIndex: 'stock_quantity',
      key: 'stock',
      render: (stock) => {
        const stockInfo = getStockStatus(stock)
        return (
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span><strong>{stock}</strong> units</span>
              <Tag color={stockInfo.color}>{stockInfo.status}</Tag>
            </div>
            <Progress
              percent={stockInfo.percent}
              size="small"
              strokeColor={stockInfo.color}
              showInfo={false}
            />
          </div>
        )
      }
    },
    {
      title: 'Value',
      key: 'value',
      render: (_, record) => `₹${(record.stock_quantity * record.price).toFixed(2)}`
    },
    {
      title: 'Status',
      dataIndex: 'is_available',
      key: 'available',
      render: (isAvailable) => (
        <Tag color={isAvailable ? 'green' : 'red'}>
          {isAvailable ? 'Available' : 'Unavailable'}
        </Tag>
      )
    }
  ]

  // Calculate summary stats
  const totalProducts = inventory.length
  const lowStockProducts = inventory.filter(p => p.stock_quantity <= 5).length
  const outOfStockProducts = inventory.filter(p => p.stock_quantity === 0).length
  const totalValue = inventory.reduce((sum, p) => sum + (p.stock_quantity * p.price), 0)

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <Title level={2}>📦 Inventory Management</Title>
          <Button
            icon={<ReloadOutlined />}
            onClick={fetchInventory}
            loading={loading}
          >
            Refresh
          </Button>
        </div>

        {/* Summary Cards */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
          <Card size="small">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#1890ff' }}>{totalProducts}</div>
              <div>Total Products</div>
            </div>
          </Card>
          <Card size="small">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#faad14' }}>{lowStockProducts}</div>
              <div>Low Stock</div>
            </div>
          </Card>
          <Card size="small">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#f5222d' }}>{outOfStockProducts}</div>
              <div>Out of Stock</div>
            </div>
          </Card>
          <Card size="small">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#52c41a' }}>₹{totalValue.toFixed(2)}</div>
              <div>Total Value</div>
            </div>
          </Card>
        </div>

        {/* Alerts */}
        {(lowStockProducts > 0 || outOfStockProducts > 0) && (
          <div style={{ marginBottom: '16px' }}>
            <Space direction="vertical" style={{ width: '100%' }}>
              {outOfStockProducts > 0 && (
                <div style={{ padding: '8px 12px', backgroundColor: '#fff2f0', border: '1px solid #ffccc7', borderRadius: '6px' }}>
                  <WarningOutlined style={{ color: '#f5222d', marginRight: '8px' }} />
                  <strong>{outOfStockProducts}</strong> products are out of stock
                </div>
              )}
              {lowStockProducts > 0 && (
                <div style={{ padding: '8px 12px', backgroundColor: '#fffbe6', border: '1px solid #ffe58f', borderRadius: '6px' }}>
                  <WarningOutlined style={{ color: '#faad14', marginRight: '8px' }} />
                  <strong>{lowStockProducts}</strong> products have low stock
                </div>
              )}
            </Space>
          </div>
        )}

        <Table
          columns={columns}
          dataSource={inventory}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `Total ${total} products`
          }}
          scroll={{ x: 800 }}
        />
      </Card>
    </div>
  )
}
