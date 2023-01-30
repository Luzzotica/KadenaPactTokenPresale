import { useEffect, useState } from "react";
import { useSelector } from "react-redux";
import FlexColumn from "../../Layout/FlexColumn";
import FlexRow from "../../Layout/FlexRow";


function ReservationRender(props) {
  const tokenName = import.meta.env.VITE_TOKEN_NAME;

  const reservation = useSelector(state => state.saleInfo.reservation);

  const [amountPurchased, setAmountPurchased] = useState(0);
  const [amountPaid, setAmountPaid] = useState(0);
  useEffect(() => {
    if (Object.keys(reservation).length === 0) {
      return;
    }
    // console.log(reservation);
    setAmountPurchased(reservation['amount-token']);
    setAmountPaid(reservation['amount-token-paid']);
  }, [reservation]);

  return (
    <FlexRow className='justify-center'>
      <FlexColumn className={`gap-4 bg-opacity-50 bg-black rounded-3xl p-4 m-4 place-items-center w-72 h-32 ${props.className}`}>
        <h1 className="text-3xl text-white">Your Reservation</h1>
        <h1 className="text-xl text-white">{`${tokenName} purchased: ${amountPurchased}`}</h1>
        <h1 className="text-xl text-white">{`${tokenName} received: ${amountPaid}`}</h1>
      </FlexColumn>
    </FlexRow>  
    
  )
}

export default ReservationRender;
