function CustomButton(props) {
  console.log(props.disabled);
  return (
    <button
      disabled={props.disabled}
      className={`bg-blue-500 border-slate-100 border py-2 px-4 
        rounded-xl disabled:bg-slate-400 hover:bg-blue-700 active:bg-blue-900 
        focus:bg-blue-600  transition duration-150 ease-out ${props.className}`}
      onClick={props.onClick ? props.onClick : () => { }}>
      {props.text}
    </button>
  )
}

export default CustomButton
