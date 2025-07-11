import { useEffect, useRef, useState } from 'react'
import { message } from 'antd'

interface AudioNotificationOptions {
  enabled: boolean
  volume: number
  soundType: 'default' | 'chime' | 'bell' | 'notification'
}

interface UseAudioNotificationsReturn {
  playNewOrderSound: () => void
  playStatusUpdateSound: () => void
  requestPermission: () => Promise<boolean>
  isSupported: boolean
  settings: AudioNotificationOptions
  updateSettings: (settings: Partial<AudioNotificationOptions>) => void
}

const useAudioNotifications = (): UseAudioNotificationsReturn => {
  const audioContextRef = useRef<AudioContext | null>(null)
  const [settings, setSettings] = useState<AudioNotificationOptions>(() => {
    // Load settings from localStorage
    const saved = localStorage.getItem('vendor-audio-settings')
    return saved ? JSON.parse(saved) : {
      enabled: true,
      volume: 0.7,
      soundType: 'default'
    }
  })

  const isSupported = 'AudioContext' in window || 'webkitAudioContext' in window

  useEffect(() => {
    // Save settings to localStorage whenever they change
    localStorage.setItem('vendor-audio-settings', JSON.stringify(settings))
  }, [settings])

  useEffect(() => {
    // Initialize AudioContext on first user interaction
    const initAudioContext = () => {
      if (!audioContextRef.current && isSupported) {
        const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext
        audioContextRef.current = new AudioContextClass()
      }
    }

    // Add event listeners for user interaction
    const events = ['click', 'touchstart', 'keydown']
    events.forEach(event => {
      document.addEventListener(event, initAudioContext, { once: true })
    })

    return () => {
      events.forEach(event => {
        document.removeEventListener(event, initAudioContext)
      })
    }
  }, [isSupported])

  const createBeepSound = (frequency: number, duration: number, volume: number = 0.5) => {
    if (!audioContextRef.current || !settings.enabled) return

    const context = audioContextRef.current
    const oscillator = context.createOscillator()
    const gainNode = context.createGain()

    oscillator.connect(gainNode)
    gainNode.connect(context.destination)

    oscillator.frequency.setValueAtTime(frequency, context.currentTime)
    oscillator.type = 'sine'

    gainNode.gain.setValueAtTime(0, context.currentTime)
    gainNode.gain.linearRampToValueAtTime(volume * settings.volume, context.currentTime + 0.01)
    gainNode.gain.exponentialRampToValueAtTime(0.001, context.currentTime + duration)

    oscillator.start(context.currentTime)
    oscillator.stop(context.currentTime + duration)
  }

  const playNewOrderSound = () => {
    if (!settings.enabled || !isSupported) return

    try {
      switch (settings.soundType) {
        case 'chime':
          // Play a pleasant chime sequence
          createBeepSound(523.25, 0.2, 0.6) // C5
          setTimeout(() => createBeepSound(659.25, 0.2, 0.6), 100) // E5
          setTimeout(() => createBeepSound(783.99, 0.3, 0.6), 200) // G5
          break
        
        case 'bell':
          // Play a bell-like sound
          createBeepSound(800, 0.1, 0.8)
          setTimeout(() => createBeepSound(800, 0.1, 0.6), 150)
          setTimeout(() => createBeepSound(800, 0.2, 0.4), 300)
          break
        
        case 'notification':
          // Play a modern notification sound
          createBeepSound(440, 0.15, 0.7) // A4
          setTimeout(() => createBeepSound(554.37, 0.15, 0.7), 100) // C#5
          break
        
        default:
          // Default beep sound
          createBeepSound(800, 0.2, 0.7)
          setTimeout(() => createBeepSound(1000, 0.2, 0.5), 250)
          break
      }

      // Show browser notification if permission granted
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('New Order Received!', {
          body: 'You have received a new order. Please check your orders panel.',
          icon: '/favicon.ico',
          badge: '/favicon.ico',
          tag: 'new-order',
          requireInteraction: true
        })
      }
    } catch (error) {
      console.error('Failed to play new order sound:', error)
    }
  }

  const playStatusUpdateSound = () => {
    if (!settings.enabled || !isSupported) return

    try {
      // Play a subtle status update sound
      createBeepSound(600, 0.1, 0.4)
      setTimeout(() => createBeepSound(700, 0.1, 0.3), 100)
    } catch (error) {
      console.error('Failed to play status update sound:', error)
    }
  }

  const requestPermission = async (): Promise<boolean> => {
    if (!('Notification' in window)) {
      message.warning('Browser notifications are not supported')
      return false
    }

    if (Notification.permission === 'granted') {
      return true
    }

    if (Notification.permission === 'denied') {
      message.error('Notifications are blocked. Please enable them in browser settings.')
      return false
    }

    try {
      const permission = await Notification.requestPermission()
      if (permission === 'granted') {
        message.success('Notifications enabled successfully!')
        return true
      } else {
        message.warning('Notification permission denied')
        return false
      }
    } catch (error) {
      console.error('Failed to request notification permission:', error)
      message.error('Failed to request notification permission')
      return false
    }
  }

  const updateSettings = (newSettings: Partial<AudioNotificationOptions>) => {
    setSettings(prev => ({ ...prev, ...newSettings }))
  }

  return {
    playNewOrderSound,
    playStatusUpdateSound,
    requestPermission,
    isSupported,
    settings,
    updateSettings
  }
}

export default useAudioNotifications
