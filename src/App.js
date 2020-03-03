// App.js
// Written by Ephraim Benson on 03/03/2020


// https://willbeddow.com/api/bonapp/v1/menu/
// https://willbeddow.com/api/bonapp/v1/tots/

import React, {Component} from 'react';
import './App.css';
import sampleData from './SampleData'
import LocationButton from './Components/LocationButton'
import MealButton from './Components/MealButton'

function substringPresentInStringArray(substr, arr) {
    for (const i in arr) {
        let dish = arr[i];
        if (dish.toLowerCase().includes(substr)) {
            return true;
        }
    }
    return false;
}

function parseMenu(menu) {
    let totsData = [];
    let idNum = 0;
    for (let [diningHall_name, diningHall_object] of Object.entries(menu)) {
        let currMeals = [];
        let totsAvail = [];
        for (const meal_name in diningHall_object) {
            currMeals.push(meal_name);
            let dishesServed = diningHall_object[meal_name];
            let hasTots = substringPresentInStringArray("tots", dishesServed);
            totsAvail.push(hasTots);
        }
        totsData.push({
            id: idNum,
            location: diningHall_name.toUpperCase(),
            meals: currMeals,
            tots: totsAvail
        });
        idNum = idNum + 1;
    }
    // console.log(totsData);
    return totsData;
}

class App extends Component {
    constructor() {
        super();
        this.state = {
            loadingMenu: false,
            totData: [],
            // totData: sampleData,
            selectedLocation: null,
            selectedMeal: null
        }

        this.handleDiningHallButton = this.handleDiningHallButton.bind(this)
        this.handleMealButton = this.handleMealButton.bind(this)
    }

    componentDidMount() {        
        this.setState({loading: true})
        fetch("https://willbeddow.com/api/bonapp/v1/menu/")
            .then(response => response.json())
            .then(menu => {
                this.setState({
                    loadingMenu: false,
                    totData: parseMenu(menu)
                })
            })
    }
    
    // Button Functions
    handleDiningHallButton(diningHall) {
        this.setState({
            selectedLocation: diningHall
        })
    }
    handleMealButton(meal) {
        this.setState({
            selectedMeal: meal
        })
    }

    render() {
        const diningHallButtons = this.state.totData.map(hall => {
            return (
                <LocationButton
                    locationObject={hall}
                    handleDiningHallButton={this.handleDiningHallButton}
                    key = {hall.id}
                />
            )
        });
        
        let mealButtons
        if (this.state.selectedLocation) {
            mealButtons = this.state.selectedLocation.meals.map(meal => {
                return (
                    <MealButton 
                        meal={meal}
                        handleMealButton={this.handleMealButton}
                        key={meal}
                    />
                )
            })
        }

        let hotTots = false
        let resultReady = (this.state.selectedMeal && this.state.selectedLocation)
        if (resultReady) {
            const index = this.state.selectedLocation.meals.indexOf(this.state.selectedMeal)
            hotTots = this.state.selectedLocation.tots[index]
        }

        let interfaceElements = (     
            <div>
                <h3 className="Selection-header">Select Dining Hall:</h3>                
                {diningHallButtons}                

                <h3 className="Selection-header" hidden={!this.state.selectedLocation}>Select Meal:</h3>
                {mealButtons}
                
                <h3 className="Selection-header" hidden={!resultReady}>Result:</h3>
                <p className="Result" hidden={!resultReady}>{hotTots ? "Tots!" : "No tots. Sorry!"}</p>
            </div>   
        )

        return (
            <div className="App">
                <header className="App-header">Tot or Not</header>
                {/* <h3 className="Selection-header">Loading...</h3> */}
                {this.state.loadingMenu ? <h3 className="Selection-header">Loading...</h3> : interfaceElements}
            </div>
        );
    }
}

export default App;