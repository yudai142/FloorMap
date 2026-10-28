export async function svgToPngBlob(svgElement, width, height) {
  const svgBlob = new Blob([new XMLSerializer().serializeToString(svgElement)], { type: 'image/svg+xml;charset=utf-8' })
  const svgUrl = URL.createObjectURL(svgBlob)

  try {
    const image = new Image(width, height)
    await new Promise((resolve, reject) => {
      image.onload = resolve
      image.onerror = reject
      image.src = svgUrl
    })

    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const context = canvas.getContext('2d')
    context.fillStyle = '#ffffff'
    context.fillRect(0, 0, width, height)
    context.drawImage(image, 0, 0, width, height)

    return await new Promise((resolve) => canvas.toBlob(resolve, 'image/png'))
  } finally {
    URL.revokeObjectURL(svgUrl)
  }
}
