import React from 'react'
import { X, AlertCircle, CheckCircle2 } from 'lucide-react'

export function ErrorAlert({ message, onDismiss }) {
  return (
    <div className="alert alert-error mb-4 flex items-start gap-3">
      <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
      <div>
        <h3 className="font-semibold">エラーが発生しました</h3>
        <p className="text-sm mt-1">{message}</p>
      </div>
      {onDismiss && (
        <button onClick={onDismiss} className="btn btn-ghost btn-sm btn-circle ml-auto">
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}

export function SuccessAlert({ message, onDismiss }) {
  return (
    <div className="alert alert-success mb-4 flex items-start gap-3">
      <CheckCircle2 className="w-5 h-5 flex-shrink-0 mt-0.5" />
      <p className="text-sm flex-grow">{message}</p>
      {onDismiss && (
        <button onClick={onDismiss} className="btn btn-ghost btn-sm btn-circle">
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}
