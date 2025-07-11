import React, { useState } from 'react'
import { Card, Typography, Form, Input, Button, Space, Descriptions, Avatar, message } from 'antd'
import { UserOutlined, EditOutlined, SaveOutlined } from '@ant-design/icons'
import { useAuthStore } from '@/stores/authStore'

const { Title } = Typography

export default function ProfilePage() {
  const { vendor } = useAuthStore()
  const [editing, setEditing] = useState(false)
  const [form] = Form.useForm()

  // Handle profile update
  const handleUpdate = async (values) => {
    try {
      // Here you would update the vendor profile in Supabase
      console.log('Updating profile:', values)
      message.success('Profile updated successfully')
      setEditing(false)
    } catch (error) {
      console.error('Error updating profile:', error)
      message.error('Failed to update profile')
    }
  }

  // Start editing
  const startEditing = () => {
    form.setFieldsValue({
      name: vendor?.name,
      email: vendor?.email,
      phone: vendor?.phone,
      business_name: vendor?.business_name,
      address: vendor?.address
    })
    setEditing(true)
  }

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <Title level={2}>👤 Profile Management</Title>
          {!editing && (
            <Button
              type="primary"
              icon={<EditOutlined />}
              onClick={startEditing}
            >
              Edit Profile
            </Button>
          )}
        </div>

        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap' }}>
          {/* Profile Avatar */}
          <div style={{ textAlign: 'center' }}>
            <Avatar size={120} icon={<UserOutlined />} />
            <div style={{ marginTop: '12px' }}>
              <Button size="small">Change Photo</Button>
            </div>
          </div>

          {/* Profile Information */}
          <div style={{ flex: 1, minWidth: '300px' }}>
            {!editing ? (
              <Descriptions bordered column={1}>
                <Descriptions.Item label="Vendor Name">
                  {vendor?.name || 'Test Vendor Store'}
                </Descriptions.Item>
                <Descriptions.Item label="Email">
                  {vendor?.email || 'test_vendor@dayliz.in'}
                </Descriptions.Item>
                <Descriptions.Item label="Phone">
                  {vendor?.phone || '+91-9876543210'}
                </Descriptions.Item>
                <Descriptions.Item label="Business Name">
                  {vendor?.business_name || 'Test Business'}
                </Descriptions.Item>
                <Descriptions.Item label="Status">
                  {vendor?.is_active ? 'Active' : 'Inactive'}
                </Descriptions.Item>
                <Descriptions.Item label="Vendor Type">
                  {vendor?.vendor_type || 'External'}
                </Descriptions.Item>
                <Descriptions.Item label="Operational Model">
                  {vendor?.operational_model || 'Single Vendor'}
                </Descriptions.Item>
                <Descriptions.Item label="Commission Rate">
                  {vendor?.commission_rate ? `${(vendor.commission_rate * 100).toFixed(1)}%` : '10.0%'}
                </Descriptions.Item>
                <Descriptions.Item label="Delivery Radius">
                  {vendor?.delivery_radius_km || 5} km
                </Descriptions.Item>
                <Descriptions.Item label="Avg. Preparation Time">
                  {vendor?.avg_preparation_time_minutes || 30} minutes
                </Descriptions.Item>
                <Descriptions.Item label="Min Order Amount">
                  ₹{vendor?.min_order_amount || 100}
                </Descriptions.Item>
                <Descriptions.Item label="Rating">
                  {vendor?.rating || 4.5} / 5.0
                </Descriptions.Item>
                <Descriptions.Item label="Total Orders">
                  {vendor?.total_orders || 0}
                </Descriptions.Item>
              </Descriptions>
            ) : (
              <Form
                form={form}
                layout="vertical"
                onFinish={handleUpdate}
              >
                <Form.Item
                  name="name"
                  label="Vendor Name"
                  rules={[{ required: true, message: 'Please enter vendor name' }]}
                >
                  <Input placeholder="Enter vendor name" />
                </Form.Item>

                <Form.Item
                  name="email"
                  label="Email"
                  rules={[
                    { required: true, message: 'Please enter email' },
                    { type: 'email', message: 'Please enter valid email' }
                  ]}
                >
                  <Input placeholder="Enter email address" />
                </Form.Item>

                <Form.Item
                  name="phone"
                  label="Phone"
                  rules={[{ required: true, message: 'Please enter phone number' }]}
                >
                  <Input placeholder="Enter phone number" />
                </Form.Item>

                <Form.Item
                  name="business_name"
                  label="Business Name"
                  rules={[{ required: true, message: 'Please enter business name' }]}
                >
                  <Input placeholder="Enter business name" />
                </Form.Item>

                <Form.Item
                  name="address"
                  label="Address"
                >
                  <Input.TextArea rows={3} placeholder="Enter business address" />
                </Form.Item>

                <Form.Item>
                  <Space>
                    <Button
                      type="primary"
                      htmlType="submit"
                      icon={<SaveOutlined />}
                    >
                      Save Changes
                    </Button>
                    <Button onClick={() => setEditing(false)}>
                      Cancel
                    </Button>
                  </Space>
                </Form.Item>
              </Form>
            )}
          </div>
        </div>
      </Card>
    </div>
  )
}
