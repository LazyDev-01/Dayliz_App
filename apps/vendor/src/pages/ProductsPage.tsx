import React, { useState, useEffect } from 'react'
import { Card, Typography, Button, Space, Table, Tag, Switch, message, Modal, Form, Input, InputNumber } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined } from '@ant-design/icons'
import { useAuthStore } from '@/stores/authStore'
import { supabase } from '@/services/supabase'

const { Title } = Typography

export default function ProductsPage() {
  const { vendor } = useAuthStore()
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [modalVisible, setModalVisible] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [form] = Form.useForm()

  // Fetch products from Supabase
  const fetchProducts = async () => {
    if (!vendor?.id) return

    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('products')
        .select(`
          *,
          categories (
            id,
            name
          )
        `)
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching products:', error)
        message.error('Failed to load products')
        return
      }

      setProducts(data || [])
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to load products')
    } finally {
      setLoading(false)
    }
  }

  // Toggle product availability
  const toggleAvailability = async (productId, isAvailable) => {
    try {
      const { error } = await supabase
        .from('products')
        .update({
          is_available: isAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('id', productId)

      if (error) {
        console.error('Error updating product:', error)
        message.error('Failed to update product availability')
        return
      }

      message.success(`Product ${isAvailable ? 'enabled' : 'disabled'} successfully`)
      fetchProducts()
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to update product availability')
    }
  }

  // Handle form submission
  const handleSubmit = async (values) => {
    try {
      const productData = {
        ...values,
        vendor_id: vendor.id,
        updated_at: new Date().toISOString()
      }

      let error
      if (editingProduct) {
        // Update existing product
        const { error: updateError } = await supabase
          .from('products')
          .update(productData)
          .eq('id', editingProduct.id)
        error = updateError
      } else {
        // Create new product
        productData.created_at = new Date().toISOString()
        const { error: insertError } = await supabase
          .from('products')
          .insert([productData])
        error = insertError
      }

      if (error) {
        console.error('Error saving product:', error)
        message.error('Failed to save product')
        return
      }

      message.success(`Product ${editingProduct ? 'updated' : 'created'} successfully`)
      setModalVisible(false)
      setEditingProduct(null)
      form.resetFields()
      fetchProducts()
    } catch (error) {
      console.error('Error:', error)
      message.error('Failed to save product')
    }
  }

  // Open edit modal
  const openEditModal = (product) => {
    setEditingProduct(product)
    form.setFieldsValue(product)
    setModalVisible(true)
  }

  // Open add modal
  const openAddModal = () => {
    setEditingProduct(null)
    form.resetFields()
    setModalVisible(true)
  }

  useEffect(() => {
    fetchProducts()
  }, [vendor?.id])

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
      title: 'Price',
      dataIndex: 'price',
      key: 'price',
      render: (price) => `₹${price?.toFixed(2) || '0.00'}`
    },
    {
      title: 'Stock',
      dataIndex: 'stock_quantity',
      key: 'stock',
      render: (stock) => (
        <Tag color={stock > 10 ? 'green' : stock > 0 ? 'orange' : 'red'}>
          {stock || 0} units
        </Tag>
      )
    },
    {
      title: 'Available',
      dataIndex: 'is_available',
      key: 'available',
      render: (isAvailable, record) => (
        <Switch
          checked={isAvailable}
          onChange={(checked) => toggleAvailability(record.id, checked)}
          checkedChildren="Yes"
          unCheckedChildren="No"
        />
      )
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            size="small"
            icon={<EditOutlined />}
            onClick={() => openEditModal(record)}
          >
            Edit
          </Button>
          <Button
            size="small"
            danger
            icon={<DeleteOutlined />}
            onClick={() => {
              Modal.confirm({
                title: 'Delete Product',
                content: 'Are you sure you want to delete this product?',
                onOk: async () => {
                  const { error } = await supabase
                    .from('products')
                    .delete()
                    .eq('id', record.id)

                  if (error) {
                    message.error('Failed to delete product')
                  } else {
                    message.success('Product deleted successfully')
                    fetchProducts()
                  }
                }
              })
            }}
          >
            Delete
          </Button>
        </Space>
      )
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <Title level={2}>🛍️ Products Management</Title>
          <Space>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={openAddModal}
            >
              Add Product
            </Button>
            <Button
              icon={<ReloadOutlined />}
              onClick={fetchProducts}
              loading={loading}
            >
              Refresh
            </Button>
          </Space>
        </div>

        <div style={{ marginBottom: '16px' }}>
          <Space>
            <Tag color="green">Available: {products.filter(p => p.is_available).length}</Tag>
            <Tag color="red">Unavailable: {products.filter(p => !p.is_available).length}</Tag>
            <Tag color="orange">Low Stock: {products.filter(p => p.stock_quantity <= 10).length}</Tag>
          </Space>
        </div>

        <Table
          columns={columns}
          dataSource={products}
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

      {/* Add/Edit Product Modal */}
      <Modal
        title={editingProduct ? 'Edit Product' : 'Add New Product'}
        open={modalVisible}
        onCancel={() => {
          setModalVisible(false)
          setEditingProduct(null)
          form.resetFields()
        }}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <Form.Item
            name="name"
            label="Product Name"
            rules={[{ required: true, message: 'Please enter product name' }]}
          >
            <Input placeholder="Enter product name" />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
          >
            <Input.TextArea rows={3} placeholder="Enter product description" />
          </Form.Item>

          <Form.Item
            name="price"
            label="Price (₹)"
            rules={[{ required: true, message: 'Please enter price' }]}
          >
            <InputNumber
              min={0}
              step={0.01}
              style={{ width: '100%' }}
              placeholder="0.00"
            />
          </Form.Item>

          <Form.Item
            name="stock_quantity"
            label="Stock Quantity"
            rules={[{ required: true, message: 'Please enter stock quantity' }]}
          >
            <InputNumber
              min={0}
              style={{ width: '100%' }}
              placeholder="0"
            />
          </Form.Item>

          <Form.Item
            name="is_available"
            label="Available"
            valuePropName="checked"
            initialValue={true}
          >
            <Switch checkedChildren="Yes" unCheckedChildren="No" />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                {editingProduct ? 'Update Product' : 'Add Product'}
              </Button>
              <Button onClick={() => {
                setModalVisible(false)
                setEditingProduct(null)
                form.resetFields()
              }}>
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}
