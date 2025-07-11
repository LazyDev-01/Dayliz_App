import React from 'react'
import {
  Card,
  Row,
  Col,
  Typography,
  Space,
  Tabs,
  Divider
} from 'antd'
import {
  SettingOutlined,
  SoundOutlined,
  UserOutlined,
  BellOutlined
} from '@ant-design/icons'
// import AudioSettings from '@/components/settings/AudioSettings'

const { Title, Text } = Typography
const { TabPane } = Tabs

export default function Settings() {
  return (
    <div style={{ padding: '24px' }}>
      {/* Page Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Space direction="vertical" size="small">
            <Title level={2} style={{ margin: 0 }}>
              <Space>
                <SettingOutlined />
                Settings
              </Space>
            </Title>
            <Text type="secondary">
              Configure your vendor panel preferences and notifications
            </Text>
          </Space>
        </Col>
      </Row>

      <Divider />

      {/* Settings Tabs */}
      <Tabs defaultActiveKey="audio" size="large">
        <TabPane
          tab={
            <Space>
              <SoundOutlined />
              Audio & Notifications
            </Space>
          }
          key="audio"
        >
          <Card>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
              <div>
                <Title level={4}>Audio & Notification Settings</Title>
                <Text type="secondary">
                  Audio and notification settings will be available in a future update.
                </Text>
              </div>
            </Space>
          </Card>
        </TabPane>

        <TabPane
          tab={
            <Space>
              <UserOutlined />
              Profile
            </Space>
          }
          key="profile"
        >
          <Card>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
              <div>
                <Title level={4}>Profile Settings</Title>
                <Text type="secondary">
                  Profile settings will be available in a future update.
                </Text>
              </div>
            </Space>
          </Card>
        </TabPane>

        <TabPane
          tab={
            <Space>
              <BellOutlined />
              Preferences
            </Space>
          }
          key="preferences"
        >
          <Card>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
              <div>
                <Title level={4}>General Preferences</Title>
                <Text type="secondary">
                  Additional preferences will be available in a future update.
                </Text>
              </div>
            </Space>
          </Card>
        </TabPane>
      </Tabs>
    </div>
  )
}
