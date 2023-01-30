import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CustomButton from '../../Layout/CustomButton';
import FlexColumn from '../../Layout/FlexColumn';
import FlexRow from '../../Layout/FlexRow';
import { reserveTokens } from '../store/saleSlice';

function ReserveRender() {
  const chainId = import.meta.env.VITE_CHAIN_ID;

  const dispatch = useDispatch();

  const account = useSelector(state => state.kadenaInfo.account);
  const whitelistInfo = useSelector(state => state.saleInfo.whitelistInfo);
  const currentTier = useSelector(state => state.saleInfo.currentTier);
  const [price, setPrice] = useState(-1);
  const [purchaseAmount, setPurchaseAmount] = useState(-1);
  const [tokenMin, setTokenMin] = useState(-1);
  const [tokenMax, setTokenMax] = useState(-1);
  const [remainingPurchase, setRemainingPurchase] = useState(-1);
  useEffect(() => {
    if (Object.keys(currentTier).length === 0) {
      return;
    }

    // If the tier type is WL
    if ('tier-type' in currentTier 
      && currentTier['tier-type'] === 'WL') {
      // console.log('current tier: ', currentTier);
      // console.log('whitelist info: ', whitelistInfo);

      // Whitelisted if the tier is our whitelist 
      // and the whitelist purchase amount is not -1
      if (currentTier['tier-id'] in whitelistInfo
        && whitelistInfo[currentTier['tier-id']] >= 0) {
        setPurchaseAmount(whitelistInfo[currentTier['tier-id']]['int']);
        setTokenMin(currentTier['min-token']);
        setTokenMax(currentTier['max-token']);
        setPrice(currentTier['token-per-fungible']);
      }
      else { // If we aren't whitelisted, set the price to -1
        setPurchaseAmount(-1);
        setTokenMin(-1);
        setTokenMax(-1);
        setPrice(-1);
      }
    }
    else {
      setPurchaseAmount(-1);
      setTokenMin(-1);
      setTokenMax(-1);
      setPrice(currentTier['token-per-fungible']);
    }
    
  }, [currentTier, whitelistInfo]);

  useEffect(() => {
    if (purchaseAmount === -1 || tokenMin === -1) {
      setRemainingPurchase(-1);
    }
    setRemainingPurchase(tokenMin - purchaseAmount);
  }, [purchaseAmount, tokenMin]);

  const [amount, setAmount] = useState(1);
  const [canMint, setCanMint] = useState(false);
  const [cantMintReason, setCantMintReason] = useState('');
  useEffect(() => {
    // If the amount is outside of the bounds set, stop it
    if (tokenMin !== -1 && amount < tokenMin * price) {
      setCanMint(false);
      setCantMintReason(`Amount is less than the minimum amount of ${tokenMin} tokens`);
    }
    else if (tokenMax !== -1 && amount > tokenMax * price) {
      setCanMint(false);
      setCantMintReason(`Amount is greater than the maximum amount of ${tokenMax} tokens`);
    }
    else {
      setCanMint(true);
      setCantMintReason('');
    }
  }, [amount, tokenMin, tokenMax, price]);

  const onInputChanged = (e) => {
    let id = e.target.id;
    if (id === 'amount') {
      let amount = Number(e.target.value);
      setAmount(amount);
    }
  }

  const reserve = () => {
    dispatch(reserveTokens(chainId, account, amount));
  }

  return (
    <div className="flex flex-row gap-2 justify-center place-items-center">
      <FlexColumn className="w-96 gap-4 justify-center place-items-center">
        {price >= 0 && purchaseAmount !== -1 ? 
          <FlexColumn className="flex-auto gap-4 text-center content-center">
            <p className='text-xl'>
              {remainingPurchase === 0 ? 
                "Can't reserve more from this tier!"
              :
                `You can purchase tokens from this tier. ${remainingPurchase}${remainingPurchase === 1.0 ? ' time' : ' times'}`
              }
            </p>
          </FlexColumn>
        :
          <></>
        }
        {price >= 0 || (currentTier['tier-type'] === 'WL' && remainingPurchase > 0) ? 
          <FlexColumn className="flex-auto w-64 gap-4 place-items-stretch">
            <FlexRow className="flex-1 gap-2 place-items-stretch">
              <input 
                id="amount"
                type="number"
                value={amount}
                onChange={onInputChanged}
                className='flex-auto bg-slate-800 rounded-md p-1'>
              </input>
            </FlexRow>
            {canMint ? <CustomButton
              className='flex-auto'
              text={`Mint`}
              onClick={reserve}/> 
              : 
              <span className='text-3xl'>{cantMintReason}</span>
            }
          </FlexColumn>
        : 
          <></>
        }
        
      </FlexColumn>
      
    </div>
  )
}

export default ReserveRender;
