/*
https://willbeddow.com/api/bonapp/v1/menu/
https://willbeddow.com/api/bonapp/v1/tots/
 */

import React, {Component} from 'react';
import './App.css';
import sampleData from './SampleData'

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
    console.log(totsData);
    return totsData;
}

class App extends Component {
    constructor() {
        super();
        this.state = {
            loadingMenu: false,
            totData: [],
            // totData: sampleData,
            chosenDHall: null,
            chosenMeal: null
        }
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
            chosenDHall: diningHall
        })
    }
    handleMealButton(meal) {
        this.setState({
            chosenMeal: meal
        })
    }

    render() {
        const diningHallButtons = this.state.totData.map(hall => {
            return (
                <button key={hall.id} onClick={() => this.handleDiningHallButton(hall)}>{hall.location}</button>
            )
        });
        
        let mealButtons
        if (this.state.chosenDHall) {
            mealButtons = this.state.chosenDHall.meals.map(meal => {
                return (<button key={meal} onClick={() => this.handleMealButton(meal)}>{meal}</button>)
            })
        }

        let hotTots = false
        let resultReady = (this.state.chosenMeal && this.state.chosenDHall)
        if (resultReady) {
            const index = this.state.chosenDHall.meals.indexOf(this.state.chosenMeal)
            hotTots = this.state.chosenDHall.tots[index]
        }

        let interfaceElements = (     
            <div>
                <h3 className="Selection-header">Select Dining Hall:</h3>                
                {diningHallButtons}                

                <h3 className="Selection-header" hidden={!this.state.chosenDHall}>Select Meal:</h3>
                {mealButtons}
                
                <h4 className="Selection-header" hidden={!resultReady}>Result:</h4>
                <p className="Result" hidden={!resultReady}>{hotTots ? "Tots!" : "No tots. Sorry!"}</p>
            </div>   
        )

        return (
            <div className="App">
                <header className="App-header">Tot or Not</header>
                {this.state.loadingMenu ? "Loading..." : interfaceElements}
            </div>
        );
    }
}

export default App;