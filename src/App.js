// App.js

// Menu APIs available at:
// https://willbeddow.com/api/bonapp/v1/menu/
// https://willbeddow.com/api/bonapp/v1/tots/

import React, {Component} from 'react';
import './App.css';

function searchStringInArray (str, strArray) {
    for (var j=0; j<strArray.length; j++) {
        if (strArray[j].toLowerCase().includes(str)) {
            return j
        }
    }
    return -1;
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
            let hasTots = dishesServed[searchStringInArray("tots", dishesServed)]
            totsAvail.push(hasTots)
        }
        totsData.push({
            id: idNum,
            location: diningHall_name.toUpperCase(),
            meals: currMeals,
            tots: totsAvail
        });
        idNum = idNum + 1;
        console.log(totsAvail)
    }
    console.log(totsData)
    return totsData;
}

class App extends Component {
    constructor() {
        super();
        this.state = {
            loadingMenu: false,
            totData: [],
            selectedLocationID: null,
            selectedLocation: null,
            selectedMeal: null,
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
    handleDiningHallButton(chosen) {
        const alreadySelected = (this.state.selectedLocationID === chosen.id)

        if (alreadySelected) {
            this.setState({
                selectedLocationID: null,
                selectedLocation: null,
                selectedMeal: null
            })
        } else {
            this.setState({
                selectedLocationID: chosen.id,
                selectedLocation: chosen,
                selectedMeal: null
            })
        }
    }
    handleMealButton(meal) {
        if (meal === this.state.selectedMeal) {
            this.setState({
                selectedMeal: null
            })
        } else {
            this.setState({
                selectedMeal: meal
            })
        }
    }

    render() {
        const diningHallButtons = this.state.totData.map(hall => {
            const active = (this.state.selectedLocationID === this.state.totData.indexOf(hall))
            return (
                <button
                    className = {active ? "button-active" : "button"}
                    onClick = {() => this.handleDiningHallButton(hall)}
                    key = {hall.id}
                >{hall.location}</button>
            )
        });
        
        let mealButtons
        if (this.state.selectedLocation) {
            mealButtons = this.state.selectedLocation.meals.map(meal => {
                const active = (meal === this.state.selectedMeal)
                return (
                    <button
                        className = {active ? "button-active" : "button"}
                        onClick = {() => this.handleMealButton(meal)}
                        key = {meal}
                    >{meal}</button>
                )
            })
        }

        let hotTots
        let resultReady = (this.state.selectedMeal && this.state.selectedLocation)
        if (resultReady) {
            const index = this.state.selectedLocation.meals.indexOf(this.state.selectedMeal)
            hotTots = this.state.selectedLocation.tots[index]
        }

        let interfaceElements = (     
            <div>
                <h3 className="Selection-header">Select Dining Hall:</h3>      
                <div>
                    {diningHallButtons}                
                </div>          

                <h3 className="Selection-header" hidden={!this.state.selectedLocation}>Select Meal:</h3>
                <div>
                    {mealButtons}
                </div>

                <h3 className="Selection-header" hidden={!resultReady}>Result:</h3>
                <p className="Result" hidden={!resultReady}>{hotTots ? ("Yes, " + hotTots + "!"): "Sorry, no tots here."}</p>
            </div>   
        )

        return (
            <div className="App">
                <header className="App-header">Tot or Not</header>
                {this.state.loadingMenu ? <h3>Loading...</h3> : interfaceElements}
            </div>
        );
    }
}

export default App;