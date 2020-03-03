import React from 'react'

const LocationButton = (props) => {
    return (
        <button
            className = "button"
            onClick={ () =>
                props.handleDiningHallButton(props.locationObject)
            }
        >{props.locationObject.location}</button>
    )
}

export default LocationButton