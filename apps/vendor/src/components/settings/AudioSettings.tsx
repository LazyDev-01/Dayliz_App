import React from 'react'
import {
  Card,
  Switch,
  Slider,
  Select,
  Button,
  Space,
  Typography,
  Divider,
  Row,
  Col,
  Alert
} from 'antd'
import {
  SoundOutlined,
  NotificationOutlined,
  VolumeUpOutlined,
  PlayCircleOutlined
} from '@ant-design/icons'
import useAudioNotifications from '@/hooks/useAudioNotifications'

const { Title, Text } = Typography
const { Option } = Select

const AudioSettings: React.FC = () => {
  const {
    playNewOrderSound,
    playStatusUpdateSound,
    requestPermission,
    isSupported,
    settings,
    updateSettings
  } = useAudioNotifications()

  const handleVolumeChange = (value: number) => {
    updateSettings({ volume: value / 100 })
  }

  const handleSoundTypeChange = (value: string) => {
    updateSettings({ soundType: value as any })
  }

  const handleEnabledChange = (enabled: boolean) => {
    updateSettings({ enabled })
  }

  const testNewOrderSound = () => {
    playNewOrderSound()
  }

  const testStatusSound = () => {
    playStatusUpdateSound()
  }

  if (!isSupported) {
    return (
      <Card>
        <Alert
          message="Audio Not Supported"
          description="Your browser doesn't support audio notifications. Please use a modern browser for the best experience."
          type="warning"
          showIcon
        />
      </Card>
    )
  }

  return (
    <Card
      title={
        <Space>
          <SoundOutlined />
          <span>Audio & Notification Settings</span>
        </Space>
      }
    >
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        {/* Enable/Disable Audio */}
        <Row justify="space-between" align="middle">
          <Col>
            <Space direction="vertical" size="small">
              <Text strong>Enable Audio Notifications</Text>
              <Text type="secondary">
                Play sounds when new orders arrive or status changes
              </Text>
            </Space>
          </Col>
          <Col>
            <Switch
              checked={settings.enabled}
              onChange={handleEnabledChange}
              checkedChildren="ON"
              unCheckedChildren="OFF"
            />
          </Col>
        </Row>

        <Divider />

        {/* Volume Control */}
        <div>
          <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
            <Col>
              <Space>
                <VolumeUpOutlined />
                <Text strong>Volume</Text>
              </Space>
            </Col>
            <Col>
              <Text type="secondary">{Math.round(settings.volume * 100)}%</Text>
            </Col>
          </Row>
          <Slider
            min={0}
            max={100}
            value={Math.round(settings.volume * 100)}
            onChange={handleVolumeChange}
            disabled={!settings.enabled}
            marks={{
              0: '0%',
              25: '25%',
              50: '50%',
              75: '75%',
              100: '100%'
            }}
          />
        </div>

        <Divider />

        {/* Sound Type Selection */}
        <div>
          <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
            <Col>
              <Space direction="vertical" size="small">
                <Text strong>Sound Type</Text>
                <Text type="secondary">
                  Choose the type of sound for new order notifications
                </Text>
              </Space>
            </Col>
            <Col>
              <Select
                value={settings.soundType}
                onChange={handleSoundTypeChange}
                disabled={!settings.enabled}
                style={{ width: 120 }}
              >
                <Option value="default">Default</Option>
                <Option value="chime">Chime</Option>
                <Option value="bell">Bell</Option>
                <Option value="notification">Modern</Option>
              </Select>
            </Col>
          </Row>
        </div>

        <Divider />

        {/* Test Sounds */}
        <div>
          <Text strong style={{ marginBottom: 16, display: 'block' }}>
            Test Sounds
          </Text>
          <Space>
            <Button
              icon={<PlayCircleOutlined />}
              onClick={testNewOrderSound}
              disabled={!settings.enabled}
            >
              Test New Order Sound
            </Button>
            <Button
              icon={<PlayCircleOutlined />}
              onClick={testStatusSound}
              disabled={!settings.enabled}
            >
              Test Status Update Sound
            </Button>
          </Space>
        </div>

        <Divider />

        {/* Browser Notifications */}
        <div>
          <Row justify="space-between" align="middle">
            <Col>
              <Space direction="vertical" size="small">
                <Text strong>Browser Notifications</Text>
                <Text type="secondary">
                  Show desktop notifications for new orders
                </Text>
              </Space>
            </Col>
            <Col>
              <Button
                icon={<NotificationOutlined />}
                onClick={requestPermission}
                disabled={!settings.enabled}
              >
                {Notification.permission === 'granted' ? 'Enabled' : 'Enable Notifications'}
              </Button>
            </Col>
          </Row>
          
          {Notification.permission === 'denied' && (
            <Alert
              message="Notifications Blocked"
              description="Please enable notifications in your browser settings to receive desktop alerts for new orders."
              type="warning"
              showIcon
              style={{ marginTop: 16 }}
            />
          )}
        </div>

        <Divider />

        {/* Usage Tips */}
        <Alert
          message="Tips for Best Experience"
          description={
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>Keep this tab active or pinned for reliable notifications</li>
              <li>Ensure your browser allows sound autoplay for this site</li>
              <li>Test sounds regularly to ensure they're working</li>
              <li>Adjust volume based on your work environment</li>
            </ul>
          }
          type="info"
          showIcon
        />
      </Space>
    </Card>
  )
}

export default AudioSettings
