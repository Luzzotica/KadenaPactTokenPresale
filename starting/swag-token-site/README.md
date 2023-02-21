# Overview

This website is used to communicate with the token sale smart contract.

To change the chain, the contract name, the sale name, and the fungibles being used, change the values within the `.env` file.

Run the project locally using `npm run dev`.

You can build the project using `npm run build`.

The website was built using `tailwindcss`, `react`, and `vite`.

# To Use

If you just want to use this website to run your sale, you can fork it, and change the values in the `.env` file to point to your smart contract.

Then, you build and deploy the website to your own URL.

Done!

# To Copy

This website was designed to allow you to copy and paste its `TokeSalePage` component into another application with a little bit of work.

It is assumed that the application you are copying into uses `react` and `vite`. If it doesn't, you can't copy this the working component into your website without changing the styling and .env file.

## Install Dependencies

Install redux, kadena libs, and toastify for react:

`npm install react-redux @reduxjs/toolkit redux-thunk @kadena/chainweb-node-client @kadena/cryptography-utils react-toastify`

Install tailwindcss for vite by following the instructions [here](https://tailwindcss.com/docs/guides/vite)

## Copy the components into your site

Copy the `src/components` folder into your website.

If you already have a components folder, you can copy the subdirectories `ContractRendering`, `KDAWallet`, `Layout`, and `TxToast` into the components folder of your site.

## Set Things Up

Add redux to your main.jsx like so:

```javascript
import { Provider } from 'react-redux'
import store from './components/ContractRendering/store/store'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Provider store={store}>
      <App />
    </Provider>
  </React.StrictMode>
)
```

Add the `TokenSalePage`page to your website by adding it as an element:

```javascript
import TokenSalePage from './components/ContractRendering/TokenSalePage'

function App() {

  return (
    <div className="App">
      <TokenSalePage/>
    </div>
  )
}
```

## Setup the .env file

If you have no .env file, you can copy the .env file from this repo into your website, and change the values.  
If you already have one, feel free to copy the .env file from this repo into your .env file.  
Next, change each of the values to be what you need them to be, based on where, and how you deployed your smart contract and spun up the sale on that smart contract.

You're finished! 