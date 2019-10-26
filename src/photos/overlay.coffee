import {Component, useState, useContext} from "react"
import h from "@macrostrat/hyper"
import {ModalGateway, Modal, Carousel} from 'react-images'
import {PhotoLibraryContext} from './context'

PhotoGallery = (props)->
  {images, isOpen, onClose, rest...} = props
  # We just disable this until we figure it out.
  return null
  [ix, setIndex] = useState(0)
  increment = (step)-> ->
    newIx = (ix+step)%images.length
    setIndex(newIx)

  h ModalGateway, null, [
    h.if(isOpen), Modal, {onClose}, [
      h Carousel, {
        views: images
        currentIndex: ix
        rest...
      }
    ]
  ]

PhotoOverlay = (props)->
  {photos, computePhotoPath} = useContext(PhotoLibraryContext)
  return null if not photos?
  {photoIDs, rest...} = props

  displayedPhotos = photoIDs.map (id)=>
    photos.find (d)->d.id == id

  images = displayedPhotos.map (d)->
    src = computePhotoPath(d)
    {src, caption: d.note}

  h PhotoGallery, {
    images
    rest...
  }

export {PhotoOverlay}
