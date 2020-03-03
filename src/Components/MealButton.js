import React from 'react'

const MealButton = (props) => {
    return(
        <button
            className = "button"
            onClick = { () =>
                props.handleMealButton(props.meal)
            }
        >{props.meal}</button>
    )
}

export default MealButton