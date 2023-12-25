#[test_only]
module fund::fund_test {
   use sui::test_scenario::{Self as ts, next_tx};
    use fund::fund_project as fp;
    use fund::fund_project::{Fund_Balances,AdminCap,ShareHolders,ShareHoldersNew,create_shareholdernew,return_total_fund};
    use sui::coin::{Self,Coin,mint_for_testing};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::balance;
    use sui::table;
    use std::vector;
    use sui::test_utils::{assert_eq};

#[test]

fun admin_decide_shareholders_percentage() {

   let owner: address = @0xA;
   let test_address1: address = @0xB;
   let test_address2: address = @0xC;
   let test_address3: address = @0xD;
   let test_address4: address = @0xE;
   
   let scenario_test = ts::begin(owner);
   let scenario = &mut scenario_test;

   // check init function
   next_tx(scenario,owner);
   {
   fp::init_for_testing(ts::ctx(scenario));
   };

   // check set_shareholders function 
   next_tx(scenario,owner); 
   {
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shared_ShareHolders_ref = &mut shared_ShareHolders; 
     let admin_cap = ts::take_from_sender<AdminCap>(scenario);
   
     let shareholder_vector  = vector::empty<ShareHoldersNew>();
     
     let user1 = create_shareholdernew(test_address1, 50);
     let user2 = create_shareholdernew(test_address2, 50);
      
     vector::push_back(&mut shareholder_vector, user1);
     vector::push_back(&mut shareholder_vector, user2);

     fp::set_shareholders(&admin_cap, shared_ShareHolders_ref, shareholder_vector);
 
      ts::return_shared(shared_ShareHolders);
      ts::return_to_sender(scenario,admin_cap);
   };
   next_tx(scenario,owner);
   {
      // check percentange of shareholders is equal to 20 
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shareholder1 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address1);
     let shareholder2 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address2);

     assert_eq(shareholder1, 50);
     assert_eq(shareholder2, 50);

     ts::return_shared(shared_ShareHolders);
   };
   next_tx(scenario,owner);
   { 
    // lets call this function again to check table::remove work and increase the shareholdersnumber to 4.
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shared_ShareHolders_ref = &mut shared_ShareHolders; 
     let admin_cap = ts::take_from_sender<AdminCap>(scenario);
   
     let shareholder_vector  = vector::empty<ShareHoldersNew>();
     
     let user1 = create_shareholdernew(test_address1, 25);
     let user2 = create_shareholdernew(test_address2, 25);
     let user3 = create_shareholdernew(test_address3, 25);
     let user4 = create_shareholdernew(test_address4, 25);
      
     vector::push_back(&mut shareholder_vector, user1);
     vector::push_back(&mut shareholder_vector, user2);
     vector::push_back(&mut shareholder_vector, user3);
     vector::push_back(&mut shareholder_vector, user4);
 
     fp::set_shareholders(&admin_cap, shared_ShareHolders_ref, shareholder_vector);

     ts::return_shared(shared_ShareHolders);
     ts::return_to_sender(scenario,admin_cap);

   };

   next_tx(scenario,owner); 
   {
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shareholder1 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address1);
     let shareholder2 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address2);
     let shareholder3 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address3);
     let shareholder4 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address4);

     assert_eq(shareholder1, 25);
     assert_eq(shareholder2, 25);
     assert_eq(shareholder3, 25);
     assert_eq(shareholder4, 25);

     ts::return_shared(shared_ShareHolders);
   };

   next_tx(scenario,owner);
   {
    // lets call this function again and now lets decrease the shareholders number 4 to 3.
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shared_ShareHolders_ref = &mut shared_ShareHolders; 
     let admin_cap = ts::take_from_sender<AdminCap>(scenario);
   
     let shareholder_vector  = vector::empty<ShareHoldersNew>();
     
     let user1 = create_shareholdernew(test_address1, 30);
     let user2 = create_shareholdernew(test_address2, 30);
     let user3 = create_shareholdernew(test_address3, 40);
    
     vector::push_back(&mut shareholder_vector, user1);
     vector::push_back(&mut shareholder_vector, user2);
     vector::push_back(&mut shareholder_vector, user3);
   
     fp::set_shareholders(&admin_cap, shared_ShareHolders_ref, shareholder_vector);
     
     ts::return_shared(shared_ShareHolders);
     ts::return_to_sender(scenario,admin_cap);

   };

   next_tx(scenario,owner);
   {
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shareholder1 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address1);
     let shareholder2 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address2);
     let shareholder3 = fp::return_shareholder_percentage(&shared_ShareHolders, test_address3);

     assert_eq(shareholder1, 30);
     assert_eq(shareholder2, 30);
     assert_eq(shareholder3, 40);
  
     ts::return_shared(shared_ShareHolders);

   };

    ts::end(scenario_test);
}

#[test]
fun users_deposit_fund() {

   let owner: address = @0xA;
   let test_address1: address = @0xB;

   let scenario_test = ts::begin(owner);
   let scenario = &mut scenario_test;

   // check init function
   next_tx(scenario,owner);
   {
      fp::init_for_testing(ts::ctx(scenario));
   };
   
   //user1 deposits 1000 SUI
   next_tx(scenario,test_address1);
   {
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let deposit_amount = mint_for_testing<SUI>(1000, ts::ctx(scenario));
      
      fp::deposit_fund(&mut fund_balances, deposit_amount, ts::ctx(scenario)); 

      ts::return_shared(fund_balances);
   };
     
    // check total_fund is equal to 1000  
    next_tx(scenario,test_address1);
     {
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);

      let total_fund_balances = return_total_fund(&fund_balances);
      assert_eq(total_fund_balances, 1000);

      ts::return_shared(fund_balances);
     };
      //user1 deposits 10000 SUI
    next_tx(scenario,test_address1);
       {
       let fund_balances = ts::take_shared<Fund_Balances>(scenario);
       let deposit_amount = mint_for_testing<SUI>(10000, ts::ctx(scenario));
       
       fp::deposit_fund(&mut fund_balances, deposit_amount, ts::ctx(scenario)); 

       ts::return_shared(fund_balances);
       };
      // check total_fund is equal to 11000 
    next_tx(scenario,test_address1);
     {
        let fund_balances = ts::take_shared<Fund_Balances>(scenario);

        let total_fund_balances = return_total_fund(&fund_balances);
         assert_eq(total_fund_balances, 11000);

        ts::return_shared(fund_balances);
     };

    next_tx(scenario,owner);
   {
       let fund_balances = ts::take_shared<Fund_Balances>(scenario); 
       let admin_cap = ts::take_from_sender<AdminCap>(scenario);
       let withdraw_amount:u64 = 1000; 

       fp::admin_withdraw(&admin_cap,&mut fund_balances, withdraw_amount, ts::ctx(scenario));
        
       let total_fund_balances = return_total_fund(&fund_balances);
        assert_eq(total_fund_balances, 10000);
   
       ts::return_to_sender(scenario,admin_cap);
       ts::return_shared(fund_balances);
   };
   
   ts::end(scenario_test);
}


}