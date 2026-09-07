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
    <div className="alert alert-error shadow-lg animate-fade-in">
      <AlertCircle className="w-5 h-5 flex-shrink-0" />
      <div className="flex-1">
        <h3 className="font-semibold">エラーが発生しました</h3>
        <p className="text-sm mt-1">{message}</p>
      </div>
      {onDismiss && (
        <button onClick={onDismiss} className="btn btn-ghost btn-sm btn-circle">
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
    <div className="alert alert-success shadow-lg animate-fade-in">
      <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
      <p className="text-sm">{message}</p>
      {onDismiss && (
        <button onClick={onDismiss} className="btn btn-ghost btn-sm btn-circle">
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}
