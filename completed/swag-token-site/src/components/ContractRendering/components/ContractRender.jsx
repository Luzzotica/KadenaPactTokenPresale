import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import FlexColumn from '../../Layout/FlexColumn';
import FlexRow from '../../Layout/FlexRow';
import { setCurrentTier } from '../store/saleSlice';
import { formatCountdown, getCurrentTier } from '../store/saleSliceHelpers';

function ContractRender() {
  const fungibleName = import.meta.env.VITE_FUNGIBLE_NAME;
  const tokenName = import.meta.env.VITE_TOKEN_NAME;

  const dispatch = useDispatch();

  const saleData = useSelector(state => state.saleInfo.saleData);
  const [saleStatus, setSaleStatus] = useState('');
  const totalSupply = useSelector(state => state.saleInfo.totalSupply);
  const totalSold = useSelector(state => state.saleInfo.totalSold);
  useEffect(() => {
    if (Object.keys(saleData).length === 0) {
      return;
    }

    if (totalSupply === totalSold) {
      setSaleStatus('complete');
    }
  }, [totalSupply, totalSold]);

  const currentTier = useSelector(state => state.saleInfo.currentTier);
  const [timerStatus, setTimerStatus] = useState('before');
  const [tierName, setTierName] = useState('');
  const [endTime, setEndTime] = useState(new Date());
  const [priceText, setPriceText] = useState('');
  useEffect(() => {
    // console.log(collectionData);
    if (Object.keys(currentTier).length === 0) {
      // console.log('no collection data'); 
      return;
    }
    let tierId = currentTier['tier-id'];
    setTierName(tierId);

    if (currentTier.cost < 0) {
      setPriceText('-');
    }
    else if (currentTier.cost === 0) {
      setPriceText('Free');
    }
    else {
      setPriceText(`${currentTier['token-per-fungible']} ${tokenName} per ${fungibleName}`);
    }
    
    setTimerStatus(currentTier['status'])
    setEndTime(new Date(currentTier['end-time']['time']));
  }, [currentTier]);


  var timer
  const [countdown, setCountdown] = useState({});
  useEffect(() => {
    // console.log('tier has end', tierHasEnd);
    // console.log(timerStatus);
    if (timerStatus === 'final') {
      clearInterval(timer);
    }
    else {
      // If we already have a timer, clear it
      if (timer) {
        clearInterval(timer);
      }
      timer = setInterval(() => { 
        let countdownData = formatCountdown(endTime)
        setCountdown(countdownData);
        if (new Date() > endTime) {
          dispatch(setCurrentTier(getCurrentTier(saleData.tiers)));
        }
      }, 1000);
    }
    
    return () => {
      clearInterval(timer);
    }
  }, [timerStatus, endTime, saleData]);

  return (
    <FlexColumn className='gap-10'>
      {saleStatus === 'complete' ?
        <h1 className='text-white text-7xl font-extrabold'>Sale Complete!</h1>
      :
        <FlexColumn className='gap-10'>
          <h1 className='text-7xl text-center'>{timerStatus === 'inactive' ? 'Sale Inactive' : tierName}</h1>
          {timerStatus !== 'final' && timerStatus !== 'inactive' ? 
            <FlexColumn className="flex-1 text-center">
              <p className='text-3xl'>{timerStatus === 'before' ? 'Sale Starts In' : 'Time Remaining'}</p>
              <FlexRow className='gap-4 justify-center'> 
                {countdown.days > 0 ? <FlexColumn className='w-32'>
                  <h1 className='flex-auto text-white text-7xl font-extrabold'>{countdown.days}</h1>
                  <p className='text-xl'>Days</p>
                </FlexColumn> : <></>}
                <FlexColumn className='w-32'>
                  <h1 className='flex-auto text-white text-7xl font-extrabold'>{countdown.hours}</h1>
                  <p className='text-xl'>Hours</p>
                </FlexColumn>
                <FlexColumn className='w-32'>
                  <h1 className='flex-auto text-white text-7xl font-extrabold'>{countdown.minutes}</h1>
                  <p className='text-xl'>Minutes</p>
                </FlexColumn>
                <FlexColumn className='w-32'>
                  <h1 className='flex-auto text-white text-7xl font-extrabold'>{countdown.seconds}</h1>
                  <p className='text-xl'>Seconds</p>
                </FlexColumn>
              </FlexRow>
            </FlexColumn> :
            <></>}
        </FlexColumn>
      }
      
      <FlexRow className="w-full gap-10 text-center">
        <FlexColumn className="flex-auto w-64 gap-4">
          <h1 className='text-white text-5xl font-extrabold'>{priceText}</h1>
          <p className='text-xl'>Current Conversion Rate</p>
        </FlexColumn>
        <FlexColumn className="flex-auto w-64 gap-4">
          <h1 className='text-white text-5xl font-extrabold'>{totalSold} / {totalSupply}</h1>
          <p className='text-xl'>{`${tokenName} Sold`}</p>
        </FlexColumn>
      </FlexRow>
    </FlexColumn>
  )
}

export default ContractRender;
