module fund::fund_project { 

//use  0x1::Decimal;
use std::string::{Self,String};
use sui::transfer;
use sui::object::{Self,UID,ID};
use sui::url::{Self,Url};
use sui::coin::{Self,Coin};
use sui::sui::SUI;
use sui::object_table::{Self,ObjectTable};
use sui::event;
use sui::tx_context::{Self,TxContext};
use sui::vec_set::{Self, VecSet};
use sui::table::{Self, Table};
use sui::balance:: {Self, Balance};
use std::vector;
use std::debug;


const ERROR_INVALID_ARRAY_LENGTH: u64 = 0;
const ERROR_INVALID_PERCENTAGE_SUM: u64 = 1;
const ERROR_INVALID_VALUE:u64 = 2;
const ERROR_YOU_ARE_NOT_SHAREHOLDER:u64 =3;
const ERROR_INSUFFICIENT_FUNDS:u64 =4;

// share object
struct Fund_Balances has key {
    id:UID,
    total_fund: Balance<SUI>,
}

// only admin  
struct AdminCap has key {
    id:UID,
}

// share object
struct ShareHolders has key {
    id:UID,
    shareholders_percentage: Table<address, u64>, // shareholders allowance percentage of the  distrubution amount 
    shareholders_amount:Table<address, Balance<SUI>>,    // shareholders total withdraw amount 
    old_shareholders:vector<address>,
}
// object for add shareholer
struct ShareHoldersNew has drop {
    shareholder: address,
    share_percentage: u64,
}

   // =================== Initializer ===================

fun init(ctx:&mut TxContext) {

transfer::share_object(
    Fund_Balances{
        id:object::new(ctx),
        total_fund:balance::zero(),
    },
);

transfer::share_object(
    ShareHolders{
        id:object::new(ctx),
        shareholders_percentage:table::new(ctx),
        shareholders_amount:table::new(ctx),
        old_shareholders:vector::empty(),
    },
);

   // Admin capability object for the stable coin
 transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx) );

}
 // users can deposit fund to Fund_Balances share object. 

public entry fun deposit_fund(storage: &mut Fund_Balances, amount:Coin<SUI>, ctx:&mut TxContext) {
    let coin_balance: Balance<SUI> = coin::into_balance(amount);
    balance::join(&mut storage.total_fund, coin_balance);  
}

public fun shareholder_withdraw(shareholders: &mut ShareHolders, amount:u64, ctx:&mut TxContext) {
    let sender = tx_context::sender(ctx);
    // firstly, check >  Is sender shareholder? 
      assert!(
       table::contains(&shareholders.shareholders_amount, sender),
        ERROR_YOU_ARE_NOT_SHAREHOLDER   
     );
      // let take address from table
      let share_holder_balances = table::borrow_mut(&mut shareholders.shareholders_amount, sender);
      //decrease balance in table 
      let withdraw = coin::take(share_holder_balances , amount, ctx);
      // send fund to sender 
      transfer::public_transfer(withdraw, sender);       
}

public fun admin_withdraw(_:&AdminCap, fund:&mut Fund_Balances, withdraw_amount:u64, ctx:&mut TxContext) { 
    // check the input amount <= fund.total_fund - fund.locked_amount

    let withdraw: Coin<SUI> = coin::take(&mut fund.total_fund, withdraw_amount, ctx);
    transfer::public_transfer(withdraw, tx_context::sender(ctx));
}
   // calculate shareholder_withdraw_amount and add table it
public fun fund_distribution(_:&AdminCap, fund:&mut Fund_Balances, shareholder:&mut ShareHolders, distribution_amount: u64) {
    let shareholder_vector_len = vector::length(&shareholder.old_shareholders);
    let  i = 0;  
    while (i < shareholder_vector_len) {
        // take address from oldshareholder vector
        let share_holder_address = vector::borrow(&shareholder.old_shareholders, i);
        // take share_holder percentage from table
        let share_holder_percentage = table::borrow(&shareholder.shareholders_percentage, *share_holder_address);

        let share_holder_withdraw_amount =  (distribution_amount * *share_holder_percentage ) / 10000 ;
        // withdraw from fund total_fund
        let withdraw_coin = balance::split(&mut fund.total_fund, share_holder_withdraw_amount);
        // add to share_holder amount
        if (table::contains(&shareholder.shareholders_amount, *share_holder_address)) {
            let share_holder = table::borrow_mut(&mut shareholder.shareholders_amount, *share_holder_address);
            balance::join(share_holder, withdraw_coin);
        } else {
            table::add(&mut shareholder.shareholders_amount, *share_holder_address, withdraw_coin); 
        };
        i = i + 1;
    }
}

    // admin add or remove shareholders from contract
public fun set_shareholders(_: &AdminCap, receipt:&mut ShareHolders, shareholder:vector<ShareHoldersNew>) {
    // check input length >= 2 
   assert!(vector::length(&shareholder) >= 2, ERROR_INVALID_ARRAY_LENGTH);
    // check percentange sum must be equal to 100 
    let percentange_sum:u64 = 0;

    while(!vector::is_empty(&receipt.old_shareholders)) {
        let shareholder_address = vector::pop_back(&mut receipt.old_shareholders);
        table::remove(&mut receipt.shareholders_percentage, shareholder_address);
    };
     // add shareholders to table. 
    while(!vector::is_empty(&shareholder)) {
        let share_holder = vector::pop_back(&mut shareholder); 
        // add new shareholders to old_shareholders vector. 
        vector::push_back(&mut receipt.old_shareholders, share_holder.shareholder);   
        // add table to new shareholders and theirs percentange
        table::add(&mut receipt.shareholders_percentage, share_holder.shareholder , share_holder.share_percentage);
         // sum percentage
        percentange_sum= percentange_sum + share_holder.share_percentage;

    };
        // check percentage is equal to 100.
        assert!(percentange_sum == 10000, ERROR_INVALID_PERCENTAGE_SUM);
}

 // get receipt.shareholders.length 
fun get_shareholders_length(receipt:&ShareHolders): u64 {
     table::length(&receipt.shareholders_percentage)
}

#[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx); 
}
     // create a shareholder
    public fun create_shareholdernew(shareholder: address, share_percentage: u64): ShareHoldersNew {
        ShareHoldersNew { shareholder, share_percentage}
    }
    // return shareholder percentange u64.
    public fun return_shareholder_percentage(sh:&ShareHolders,recipient:address): u64  {
           let share_percentage_ref= table::borrow(&sh.shareholders_percentage, recipient);
           *share_percentage_ref / 100
    }
    // return shareholder allowance withdraw amount 
     public fun return_shareholder_allowance_amount(sh:&ShareHolders, recipient:address): u64  {
           let share_percentage_ref = table::borrow(&sh.shareholders_amount, recipient);
           balance::value(share_percentage_ref)
    }
    // return total_fund value as a u64
    public fun return_total_fund(fund: &Fund_Balances): u64 {
        balance::value(&fund.total_fund) 
   }

}