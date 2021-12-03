import './App.css';
import 'bulma/css/bulma.min.css';
import { useState } from 'react';
import { ethers } from 'ethers';
import SellKeey from './artifacts/contracts/Keey.sol/SellKeey.json';
const keeyAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const hStyle = { color: 'red' };

function App() {
  const [valueBuy, setValueBuy] = useState();
  const [totalSuply, setTotalSuply] = useState();
  const [defaultAccount, setDefaultAccount] = useState();
  const [connButtonText, setConnButtonText] = useState('Connect Wallet');
  const [errorShowing, setErrorShowing] = useState('');

  const provider = new ethers.providers.Web3Provider(window.ethereum)
  const signer = provider.getSigner()
  const contract = new ethers.Contract(keeyAddress, SellKeey.abi, signer)


  // Conect to Metamask 
  const connectWalletHandler = () => {
    if (window.ethereum && window.ethereum.isMetaMask) {
      window.ethereum.request({ method: 'eth_requestAccounts' })
        .then(result => {
          accountChangedHandler(result[0]);
          setConnButtonText('Wallet Connected');
        })
        .catch(error => {
          console.log(error.message);
        });

    } else {
      setConnButtonText('Need to install MetaMask');
    }
  }

  // Get event change Account
  const accountChangedHandler = (newAccount) => {
    setDefaultAccount(newAccount);
  }



  const chainChangedHandler = () => {
    window.location.reload();
    balanceOfContract()
  }

  window.ethereum.on('accountsChanged', accountChangedHandler);
  window.ethereum.on('chainChanged', chainChangedHandler);

  //Get balance of contract and adress contract
  async function balanceOfContract() {
    const totalSuply = (await contract.balanceOf(keeyAddress)).toString();
    setTotalSuply(totalSuply);

    const testKeey = await contract.keey();
    const testUSDT = await contract.usdt();

    console.log("Keey address:" + testKeey)
    console.log("USDT address:" + testUSDT)
  }

  balanceOfContract()



  // TEST BUY BY ETHER : DONE
  // async function sellKeey() { 
  //   if (!valueBuy) return
  //   if (typeof window.ethereum !== 'undefined') {
  //     const provider = new ethers.providers.Web3Provider(window.ethereum)
  //     const signer = provider.getSigner()
  //     const contract = new ethers.Contract(keeyAddress, SellKeey.abi, signer)
  //     const overrides = {
  //       value: ethers.utils.parseEther((valueBuy / 100).toString()),
  //       //gasLimit: 30000
  //     }
  //     const transaction = await contract.sellKeey(overrides)
  //     await transaction.wait()
  //     balanceOf()
  //   }
  // }

  // TEST BUY BY USDT : DONE
  async function sellKeey() {
    const balanceOfAddress = (await contract.balanceOf(defaultAccount)).toString();
    if (!valueBuy) return
    if (valueBuy < 1) {
      setErrorShowing("You need to buy at least some tokens!!!")
      return
    } else if (valueBuy > 2) {
      setErrorShowing("Wallet can only buy up to 2 KEEY!!!")
      return
    } else if (balanceOfAddress + valueBuy > 2) {
      setErrorShowing("Wallet can only buy up to 2 KEEY!!!")
      return
    }

    if (typeof window.ethereum !== 'undefined') {
      const transaction = await contract.sellKeeyByUsdt(Number(valueBuy))
      debugger
      await transaction.wait()
    }
    balanceOfContract()
  }



  return (
    <div className="faucet-wrapper" >
      <div className="faucet is-size-2" >
        <div className="balance-view is-size-2" > Buy Keey Coin </div>
        <button className="button is-warning" onClick={connectWalletHandler}>{connButtonText}</button>
        <div >
          <input value={valueBuy} onChange={e => setValueBuy(e.target.value)} type="number" />
        </div >
        <div className="faucet is-size-5" style={hStyle}>{errorShowing}</div>
        <div >
          <button className="button is-primary" onClick={sellKeey}> Buy Keey </button>
        </div >
        <br />
        <div>
          <div className="faucet is-size-5" > Total Suply: {totalSuply} KEEY</div>
          <div className="faucet is-size-5" > Rule: 1 Wallet can buy 1 or 2 KEEY per day! </div>
          <div className="faucet is-size-5" > Price: 1 Keey = 10000 USDT </div>
        </div >
        <br />
        < div >
          <div className="faucet is-size-5" > Wallet Adress: {defaultAccount}
          </div>
        </div >
      </div>
    </div >
  );
}

export default App;