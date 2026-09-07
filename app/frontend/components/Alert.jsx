import React, { useEffect } from 'react'
import { X, AlertCircle, CheckCircle2 } from 'lucide-react'

export function ErrorAlert({ message, onDismiss, autoClose = true, duration = 5000 }) {
  useEffect(() => {
    if (autoClose && onDismiss) {
      const timer = setTimeout(onDismiss, duration)
      return () => clearTimeout(timer)
    }
  }, [autoClose, duration, onDismiss])

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4 shadow-lg flex items-start gap-3 animate-fade-in">
      <AlertCircle className="w-5 h-5 flex-shrink-0 text-red-600 mt-0.5" />
      <div className="flex-1">
        <h3 className="font-semibold text-red-800">エラーが発生しました</h3>
        <p className="text-sm text-red-700 mt-1">{message}</p>
      </div>
      {onDismiss && (
        <button
          onClick={onDismiss}
          className="p-1 text-red-600 hover:bg-red-100 rounded-md transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}

export function SuccessAlert({ message, onDismiss, autoClose = true, duration = 5000 }) {
  useEffect(() => {
    if (autoClose && onDismiss) {
      const timer = setTimeout(onDismiss, duration)
      return () => clearTimeout(timer)
    }
  }, [autoClose, duration, onDismiss])

  return (
    <div className="bg-green-50 border border-green-200 rounded-lg p-4 shadow-lg flex items-center gap-3 animate-fade-in">
      <CheckCircle2 className="w-5 h-5 flex-shrink-0 text-green-600" />
      <p className="text-sm text-green-800">{message}</p>
      {onDismiss && (
        <button
          onClick={onDismiss}
          className="ml-auto p-1 text-green-600 hover:bg-green-100 rounded-md transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}
