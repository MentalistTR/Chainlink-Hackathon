#[test_only]
module fund::fund_test {
    use sui::test_scenario::{Self as ts, next_tx,Scenario};
    use fund::fund_project as fp;
    use fund::fund_project::{Fund_Balances,AdminCap,ShareHolders,ShareHoldersNew,create_shareholdernew,};
    use fund::usdc::{init_for_testing_usdc, USDC};
    use fund::usdt::{init_for_testing_usdt, USDT};
    use sui::coin::{Self, Coin, mint_for_testing, CoinMetadata};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::balance:: {Self, Balance};
    use sui::table;
    use std::vector;
    use sui::test_utils::{assert_eq};
    use std::string::{Self,String};
  

   fun add_share_holders(ts: &mut Scenario, perc1:u64,perc2:u64, perc3:u64, perc4:u64) {

     let owner: address = @0xA;
     let test_address1: address = @0xB;
     let test_address2: address = @0xC;
     let test_address3: address = @0xD;
     let test_address4: address = @0xE;

     next_tx(ts,owner);
     { 
     let shared_ShareHolders = ts::take_shared<ShareHolders>(ts);
     let shared_ShareHolders_ref = &mut shared_ShareHolders; 
     let admin_cap = ts::take_from_sender<AdminCap>(ts);
   
     let shareholder_vector  = vector::empty<ShareHoldersNew>();
     
     let user1 = create_shareholdernew(test_address1, perc1);
     let user2 = create_shareholdernew(test_address2, perc2);
     let user3 = create_shareholdernew(test_address3, perc3);
     let user4 = create_shareholdernew(test_address4, perc4);
      
     vector::push_back(&mut shareholder_vector, user1);
     vector::push_back(&mut shareholder_vector, user2);
     vector::push_back(&mut shareholder_vector, user3);
     vector::push_back(&mut shareholder_vector, user4);
 
     fp::set_shareholders(&admin_cap, shared_ShareHolders_ref, shareholder_vector);

     ts::return_shared(shared_ShareHolders);
     ts::return_to_sender(ts,admin_cap);

   };
 }
 //*****************************************************************************************************************************************// 

// USER deposit 10000 USDC
fun users_deposit_usdc<USDC>(ts: &mut Scenario) {

     let test_address1: address = @0xB;
     let test_address2: address = @0xC;
     let test_address3: address = @0xD;
     let test_address4: address = @0xE;

 next_tx(ts,test_address1);
    {
      let fund_balances = ts::take_shared<Fund_Balances>(ts);
      let deposit_amount1 = mint_for_testing<USDC>(10000, ts::ctx(ts));
      let usdc_metadata = ts::take_immutable<CoinMetadata<USDC>>(ts);
  
      fp::deposit_to_bag(&mut fund_balances, deposit_amount1,&usdc_metadata);

      ts::return_shared(fund_balances);
      ts::return_immutable(usdc_metadata);
   };

   }

// USER deposit 10000 USDT 
   fun users_deposit_usdt<USDT>(ts: &mut Scenario) {

     let test_address1: address = @0xB;
     let test_address2: address = @0xC;
     let test_address3: address = @0xD;
     let test_address4: address = @0xE;

 next_tx(ts,test_address2);
    {
      let fund_balances = ts::take_shared<Fund_Balances>(ts);
      let deposit_amount1 = mint_for_testing<USDT>(10000, ts::ctx(ts));
      let usdt_metadata = ts::take_immutable<CoinMetadata<USDT>>(ts);
  
      fp::deposit_to_bag(&mut fund_balances, deposit_amount1,&usdt_metadata);

      ts::return_shared(fund_balances);
      ts::return_immutable(usdt_metadata);
   };

   }
 
 // USER deposit 10000 SUI 
   fun users_deposit_sui(ts: &mut Scenario) {

     let test_address1: address = @0xB;
     let test_address2: address = @0xC;
     let test_address3: address = @0xD;
     let test_address4: address = @0xE;

 next_tx(ts,test_address1);
    {
      let fund_balances = ts::take_shared<Fund_Balances>(ts);
      let deposit_amount1 = mint_for_testing<SUI>(10000, ts::ctx(ts));
  
      fp::deposit_to_bag_sui(&mut fund_balances, deposit_amount1);

      ts::return_shared(fund_balances);
 
   };

   }

//*****************************************************************************************************************************************//

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

   next_tx(scenario, owner);
   {
   init_for_testing_usdc(ts::ctx(scenario))
   };

   //check set_shareholders function 
   next_tx(scenario,owner); 
   {
     let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
     let shared_ShareHolders_ref = &mut shared_ShareHolders; 
     let admin_cap = ts::take_from_sender<AdminCap>(scenario);
   
     let shareholder_vector  = vector::empty<ShareHoldersNew>();
     
     let user1 = create_shareholdernew(test_address1, 5000);
     let user2 = create_shareholdernew(test_address2, 5000);
      
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
     
     let user1 = create_shareholdernew(test_address1, 2500);
     let user2 = create_shareholdernew(test_address2, 2500);
     let user3 = create_shareholdernew(test_address3, 2500);
     let user4 = create_shareholdernew(test_address4, 2500);
      
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
     
     let user1 = create_shareholdernew(test_address1, 3000);
     let user2 = create_shareholdernew(test_address2, 3000);
     let user3 = create_shareholdernew(test_address3, 4000);
    
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

//*****************************************************************************************************************************************//

#[test]
fun deposit_funds_to_bags() {

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
   init_for_testing_usdc(ts::ctx(scenario));
   init_for_testing_usdt(ts::ctx(scenario));
   };

   //check set_shareholders function 
   next_tx(scenario,owner); 
   {
          // deposit 1000 usdt and 1000 usdc 
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let usdc_metadata = ts::take_immutable<CoinMetadata<USDC>>(scenario);
      let usdt_metadata = ts::take_immutable<CoinMetadata<USDT>>(scenario);

      let usdc_coin = mint_for_testing<USDC>(1000, ts::ctx(scenario));
      let usdt_coin = mint_for_testing<USDT>(1000, ts::ctx(scenario));

      fp:: deposit_to_bag(&mut take_share_fund_bag, usdc_coin, &usdc_metadata);
      fp:: deposit_to_bag(&mut take_share_fund_bag, usdt_coin, &usdt_metadata);
  
      ts::return_shared(take_share_fund_bag);
         ts::return_immutable(usdc_metadata);
            ts::return_immutable(usdt_metadata);
   };
 
    next_tx(scenario,owner); 
   {  
         // deposit 1000 usdt and 1000 usdc 
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let usdc_metadata = ts::take_immutable<CoinMetadata<USDC>>(scenario);
      let usdt_metadata = ts::take_immutable<CoinMetadata<USDT>>(scenario);

      let usdc_coin = mint_for_testing<USDC>(1000, ts::ctx(scenario));
      let usdt_coin = mint_for_testing<USDT>(1000, ts::ctx(scenario));

      fp:: deposit_to_bag(&mut take_share_fund_bag, usdc_coin, &usdc_metadata);
      fp:: deposit_to_bag(&mut take_share_fund_bag, usdt_coin, &usdt_metadata);
  
      ts::return_shared(take_share_fund_bag);
         ts::return_immutable(usdc_metadata);
            ts::return_immutable(usdt_metadata);
   };
   next_tx(scenario,owner); 
   {  
       // lets check usdt and usdc balance from bag. They must be equal to 2000
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let usdc_metadata = ts::take_immutable<CoinMetadata<USDC>>(scenario);
      let usdt_metadata = ts::take_immutable<CoinMetadata<USDT>>(scenario);


      let usdc_balance = fp:: get_bag_fund<USDC>(&take_share_fund_bag, &usdc_metadata);
      let usdt_balance = fp:: get_bag_fund<USDT>(&take_share_fund_bag, &usdt_metadata);

      assert_eq(balance::value(usdc_balance), 2000);
      assert_eq(balance::value(usdt_balance), 2000);
  
      ts::return_shared(take_share_fund_bag);
         ts::return_immutable(usdc_metadata);
            ts::return_immutable(usdt_metadata);
   };
    next_tx(scenario,owner); 
   {  
      // lets deposit 1000 SUI 
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let sui_coin = mint_for_testing<SUI>(1000, ts::ctx(scenario));
 
      fp::deposit_to_bag_sui(&mut take_share_fund_bag, sui_coin);

      ts::return_shared(take_share_fund_bag);
   };

   next_tx(scenario,owner); 
   {  
      // lets deposit 1000 SUI 
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let sui_coin = mint_for_testing<SUI>(1000, ts::ctx(scenario));
 
      fp::deposit_to_bag_sui(&mut take_share_fund_bag, sui_coin);

      ts::return_shared(take_share_fund_bag);
   };
   next_tx(scenario,owner); 
   {  
      // lets check SUI Balance is equal to 2000 now 
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);

      let sui_balance = fp:: get_bag_fund_SUI(&take_share_fund_bag);
  
      assert_eq(balance::value(sui_balance), 2000);
   
      ts::return_shared(take_share_fund_bag);
     
   };
   
    ts::end(scenario_test);
}

//*****************************************************************************************************************************************//

#[test]
fun admin_fund_distribution() {
   
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
 
   next_tx(scenario, owner);
     {
     init_for_testing_usdc(ts::ctx(scenario))
     };

   next_tx(scenario, owner);
     {
     init_for_testing_usdt(ts::ctx(scenario))
     };

   // add share holders
   next_tx(scenario,owner);
   {
      add_share_holders(scenario,2550,2450,2500,2500);
   };
   // user deposit 10000 USDC
   next_tx(scenario,owner);
   {
      users_deposit_usdc<USDC>(scenario); 
   };
      // user deposit 10000 USDT
   next_tx(scenario,owner);
   {
      users_deposit_usdt<USDT>(scenario);
   };
      // user deposit 10000 SUI
   next_tx(scenario,owner);
   {
      users_deposit_sui(scenario);
   };

   // lets check the USDC balance in fund_balance 
   next_tx(scenario, owner);
   {
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let usdc_metadata = ts::take_immutable<CoinMetadata<USDC>>(scenario);

      let fund_usdc_balance = fp::get_bag_fund<USDC>(&take_share_fund_bag, &usdc_metadata);
       
       assert_eq(balance::value(fund_usdc_balance), 10000);
       ts::return_shared(take_share_fund_bag);
       ts::return_immutable(usdc_metadata);
   };

      // lets check the USDT balance in fund_balance 
   next_tx(scenario, owner);
   {
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);
      let usdt_metadata = ts::take_immutable<CoinMetadata<USDT>>(scenario);

      let fund_usdc_balance = fp::get_bag_fund<USDT>(&take_share_fund_bag, &usdt_metadata);
       
       assert_eq(balance::value(fund_usdc_balance), 10000);
       ts::return_shared(take_share_fund_bag);
       ts::return_immutable(usdt_metadata);  
   };

      // lets check the USDC balance in fund_balance 
   next_tx(scenario, owner);
   {
      let take_share_fund_bag = ts::take_shared<Fund_Balances>(scenario);

      let sui_balance = fp:: get_bag_fund_SUI(&take_share_fund_bag);
  
      assert_eq(balance::value(sui_balance), 10000);
   
      ts::return_shared(take_share_fund_bag);
     

   };
   //admin to make a decision for distribution amount from total fund USDC TOKEN 5000
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"usdc";
      let name_string = string::utf8(name);

      fp::fund_distribution<USDC>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };
   next_tx(scenario,owner);
   {  
      let name  = b"usdc";
      let name_string = string::utf8(name);
      // we choose that all shareholders have %25 
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 1275);
      assert_eq(user2_target_amount , 1225);
      assert_eq(user3_target_amount , 1250);
      assert_eq(user4_target_amount , 1250);

      ts::return_shared(shared_ShareHolders);
   };

    //admin to make a decision for distribution amount from total fund USDT TOKEN 5000
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"usdt";
      let name_string = string::utf8(name);

      fp::fund_distribution<USDT>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };

      next_tx(scenario,owner);
   {  
      let name  = b"usdt";
      let name_string = string::utf8(name);
      // we choose that all shareholders have %25 
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 1275);
      assert_eq(user2_target_amount , 1225);
      assert_eq(user3_target_amount , 1250);
      assert_eq(user4_target_amount , 1250);

      ts::return_shared(shared_ShareHolders);
   };

      //admin to make a decision for distribution amount from total fund SUI TOKEN 5000
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"sui";
      let name_string = string::utf8(name);

      fp::fund_distribution<SUI>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };

      next_tx(scenario,owner);
   {  
      // we choose that all shareholders have %25 
      let name  = b"sui";
      let name_string = string::utf8(name);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 1275);
      assert_eq(user2_target_amount , 1225);
      assert_eq(user3_target_amount , 1250);
      assert_eq(user4_target_amount , 1250);

      ts::return_shared(shared_ShareHolders);
   };

    //admin to make a decision for distribution amount from total fund USDC TOKEN 2500
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 2500;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"usdc";
      let name_string = string::utf8(name);

      fp::fund_distribution<USDC>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };
   next_tx(scenario,owner);
   {  
      let name  = b"usdc";
      let name_string = string::utf8(name);
      // we choose that all shareholders have %25 
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 1912);
      assert_eq(user2_target_amount , 1837);
      assert_eq(user3_target_amount , 1875);
      assert_eq(user4_target_amount , 1875);

      ts::return_shared(shared_ShareHolders);
   };

     ts::end(scenario_test);
}

//*****************************************************************************************************************************************//

// we are apply same test with different shareholder percantage. 

#[test]
fun admin_fund_distribution2() {
   
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
 
   next_tx(scenario, owner);
     {
     init_for_testing_usdc(ts::ctx(scenario))
     };

   next_tx(scenario, owner);
     {
     init_for_testing_usdt(ts::ctx(scenario))
     };

   // add share holders
   next_tx(scenario,owner);
   {
      add_share_holders(scenario,4950,1050,3000,1000);
   };
   // user deposit 10000 USDC
   next_tx(scenario,owner);
   {
      users_deposit_usdc<USDC>(scenario); 
   };
      // user deposit 10000 USDT
   next_tx(scenario,owner);
   {
      users_deposit_usdt<USDT>(scenario);
   };
      // user deposit 10000 SUI
   next_tx(scenario,owner);
   {
      users_deposit_sui(scenario);
   };

   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"usdc";
      let name_string = string::utf8(name);

      fp::fund_distribution<USDC>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };
   next_tx(scenario,owner);
   {  
      let name  = b"usdc";
      let name_string = string::utf8(name);
      // we choose that all shareholders have %25 
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<USDC>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 2475);
      assert_eq(user2_target_amount , 525);
      assert_eq(user3_target_amount , 1500);
      assert_eq(user4_target_amount , 500);

      ts::return_shared(shared_ShareHolders);
   };

   // admin to make a decision for distribution amount from total fund USDT TOKEN 5000
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"usdt";
      let name_string = string::utf8(name);

      fp::fund_distribution<USDT>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };

      next_tx(scenario,owner);
   {  
      let name  = b"usdt";
      let name_string = string::utf8(name);
      // we choose that all shareholders have %25 
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<USDT>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 2475);
      assert_eq(user2_target_amount , 525);
      assert_eq(user3_target_amount , 1500);
      assert_eq(user4_target_amount , 500);

      ts::return_shared(shared_ShareHolders);
   };

      //admin to make a decision for distribution amount from total fund SUI TOKEN 5000
   next_tx(scenario,owner);
   {
      let admin_cap = ts::take_from_sender<AdminCap>(scenario);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let distribution_amount:u64 = 5000;
      let fund_balances = ts::take_shared<Fund_Balances>(scenario);
      let name  = b"sui";
      let name_string = string::utf8(name);

      fp::fund_distribution<SUI>(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount, name_string, ts::ctx(scenario) );

      ts::return_to_sender(scenario,admin_cap); 
      ts::return_shared(shared_ShareHolders);
      ts::return_shared(fund_balances);
   };

      next_tx(scenario,owner);
   {  
      // we choose that all shareholders have %25 
      let name  = b"sui";
      let name_string = string::utf8(name);
      let shared_ShareHolders = ts::take_shared<ShareHolders>(scenario);
      let user1_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address1);
      let user2_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address2);
      let user3_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address3);
      let user4_target_amount: u64 = fp::return_shareholder_allowance_amount<SUI>(&shared_ShareHolders, name_string, test_address4);

      assert_eq(user1_target_amount , 2475);
      assert_eq(user2_target_amount , 525);
      assert_eq(user3_target_amount , 1500);
      assert_eq(user4_target_amount , 500);

      ts::return_shared(shared_ShareHolders);
   };
   
     ts::end(scenario_test);
}


//we are doing same test for %50 %20 %10 %20
// #[test]
// fun admin_fund_distribution2() {
   
//    let owner: address = @0xA;
//    let test_address1: address = @0xB;
//    let test_address2: address = @0xC;
//    let test_address3: address = @0xD;
//    let test_address4: address = @0xE;      

//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//       fp::init_for_testing(ts::ctx(scenario));
//    };

//    next_tx(scenario, owner);
//    {
//     create_share_objects<USDC>(scenario);
//    };
//    next_tx(scenario, owner);
//      {
//      init_for_testing_usdc(ts::ctx(scenario))
//      };

//    next_tx(scenario,owner);
//    {
//       add_share_holders<USDC>(scenario,5000,2000,1000,2000);
//    };
//    next_tx(scenario,owner);
//    {
//       users_deposit_fund<USDC>(scenario);  
//    };
//    next_tx(scenario,owner);
//    {
//       let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//       let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//       let distribution_amount:u64 = 5000;
//       let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario);
      
//     fp::fund_distribution(&admin_cap, &mut fund_balances, &mut shared_ShareHolders, distribution_amount);

//       ts::return_to_sender(scenario,admin_cap);
//       ts::return_shared(shared_ShareHolders);
//       ts::return_shared(fund_balances);
//    };
//    next_tx(scenario,owner);
//    {
//       let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//       let user1_target_amount: u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address1);
//       let user2_target_amount: u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address2);
//       let user3_target_amount: u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address3);
//       let user4_target_amount: u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address4);

//       assert_eq(user1_target_amount, 2500);
//       assert_eq(user2_target_amount, 1000);
//       assert_eq(user3_target_amount, 500);
//       assert_eq(user4_target_amount, 1000);

//       ts::return_shared(shared_ShareHolders);
//    };

//   ts::end(scenario_test);
// }

// #[test]
// fun shareholder_withdraw_fund() {
   
//    let owner: address = @0xA;
//    let test_address1: address = @0xB;
   
//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//       fp::init_for_testing(ts::ctx(scenario));
//    };
   
//    next_tx(scenario, owner);
//    {
//       create_share_objects<USDC>(scenario);
//    };
//    next_tx(scenario, owner);
//      {
//        init_for_testing_usdc(ts::ctx(scenario))
//      };

//    next_tx(scenario,owner);
//    {
//        add_share_holders<USDC>(scenario,5000,2000,1000,2000);
//    };
//    next_tx(scenario,owner);
//    {
//        users_deposit_fund<USDC>(scenario); 
//    };
//    next_tx(scenario,owner);
//    {
//        admin_distributes_fund<USDC>(scenario);
//    };
//    next_tx(scenario, test_address1);
//    {    
//       // Total funds = 5000. Address1 can withdraw max 2500. Lets take 2000 now. 
//         let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//         let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario); 
//         let distribute_amount = 2000;

//        fp::shareholder_withdraw(&mut shared_ShareHolders, distribute_amount, ts::ctx(scenario));
//        // We removed the lock_amount so no need to check fund balances. It is already changed. 
//         let fund_balances_amount:u64 = fp::return_total_fund(&fund_balances);
//         assert_eq(fund_balances_amount,5000);
//        // test_address1 balance in table must be 500. 
//          let test_address1_allowance_amount:u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address1);
//          assert_eq(test_address1_allowance_amount,500);

//         ts::return_shared(shared_ShareHolders);
//         ts::return_shared(fund_balances);
//    }; 
//    next_tx(scenario, test_address1);
//    {    
//         // we can take 500 more. It will be error when address1 try to withdraw more than 500.
//         let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//         let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario); 
//         let distribute_amount = 500;
      
//        // lets check user1_account balance is equal to 2000
//          let user1_account_balance= ts::take_from_sender<Coin<USDC>>(scenario);
//          assert_eq(coin::value(&user1_account_balance), 2000);
//          ts::return_to_sender(scenario, user1_account_balance);


//          fp::shareholder_withdraw(&mut shared_ShareHolders, distribute_amount, ts::ctx(scenario));
//           // Total funds must be  = 5000.
//          let fund_balances_amount:u64 = fp::return_total_fund(&fund_balances);
//          assert_eq(fund_balances_amount,5000);

//          ts::return_shared(shared_ShareHolders);
//          ts::return_shared(fund_balances);
//    };
//    next_tx(scenario, test_address1);
//    {  
//         // lets check user1_account balance is equal to 500
//         let user1_account_balance= ts::take_from_sender<Coin<USDC>>(scenario);
//         assert_eq(coin::value(&user1_account_balance), 500);
//         ts::return_to_sender(scenario, user1_account_balance);

//        let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//        // test_address1_allowance mumst be equal to 0. 
//        let test_address1_allowance_amount:u64 = fp::return_shareholder_allowance_amount(&shared_ShareHolders, test_address1);
//        assert_eq(test_address1_allowance_amount,0);
   
//        ts::return_shared(shared_ShareHolders);
//    };
//    next_tx(scenario,owner);
//    {
//         // Admin will withdraw the remaining funds max = 5000
//       let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//       let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario); 
//       let withdraw_amount:u64 = 5000;

//       fp::admin_withdraw(&admin_cap, &mut fund_balances, withdraw_amount, ts::ctx(scenario));
   
//       ts::return_to_sender(scenario,admin_cap);
//       ts::return_shared(fund_balances);
//    };
//     next_tx(scenario,owner);
//     {    
//       // lets check owner wallet balance is equal to 5000. 
//         let owner_account_balance= ts::take_from_sender<Coin<USDC>>(scenario);
//          assert_eq(coin::value(&owner_account_balance), 5000);
//          ts::return_to_sender(scenario, owner_account_balance);

//     };
//      ts::end(scenario_test);
// }

// #[test]
// #[expected_failure(abort_code = 0000000000000000000000000000000000000000000000000000000000000002::balance::ENotEnough)]
// fun shareholder_withdraw_fund_error() {
   
//    let owner: address = @0xA;
//    let test_address1: address = @0xB;

//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//       fp::init_for_testing(ts::ctx(scenario));
//    };
//    next_tx(scenario, owner);
//    {
//       create_share_objects<USDC>(scenario);
//    };
//    next_tx(scenario, owner);
//      {
//        init_for_testing_usdc(ts::ctx(scenario))
//      };
//    next_tx(scenario,owner);
//    {
//         add_share_holders<USDC>(scenario,5000,2000,1000,2000);
//    };
//    next_tx(scenario,owner);
//    {
//        users_deposit_fund<USDC>(scenario); 
//    };
//    next_tx(scenario,owner);
//    {
//        admin_distributes_fund<USDC>(scenario);
//    };
//      next_tx(scenario,test_address1);
//     {
//         let shared_ShareHolders = ts::take_shared<ShareHolders<USDC>>(scenario);
//         let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario); 
//         let withdraw_amount= 10000;
        
//        fp::shareholder_withdraw(&mut shared_ShareHolders, withdraw_amount, ts::ctx(scenario));

//        ts::return_shared(shared_ShareHolders);
//        ts::return_shared(fund_balances);

//     };
//      ts::end(scenario_test);
// }
// // // we are expecting error. Admin try to withdraw more than 5000.
// #[test]
// #[expected_failure(abort_code = 0000000000000000000000000000000000000000000000000000000000000002::balance::ENotEnough)]
// fun admin_withdraw_fund_error() {
   
//    let owner: address = @0xA;
   
//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//       fp::init_for_testing(ts::ctx(scenario));
//    };
//    next_tx(scenario, owner);
//    {
//       create_share_objects<USDC>(scenario);
//    };
//    next_tx(scenario, owner);
//      {
//        init_for_testing_usdc(ts::ctx(scenario))
//      };
//    next_tx(scenario,owner);
//    {
//       add_share_holders<USDC>(scenario,5000,2000,1000,2000);
//    };
//    next_tx(scenario,owner);
//    {
//        users_deposit_fund<USDC>(scenario); 
//    };
//    next_tx(scenario,owner);
//    {
//        admin_distributes_fund<USDC>(scenario);
//    };
//      next_tx(scenario,owner);
//     {
//         // Admin will withdraw the remaining funds max = 5000
//        let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//        let fund_balances = ts::take_shared<Fund_Balances<USDC>>(scenario); 
//        let withdraw_amount:u64 = 10000;

//        fp::admin_withdraw(&admin_cap, &mut fund_balances, withdraw_amount, ts::ctx(scenario));
   
//        ts::return_to_sender(scenario,admin_cap);
//        ts::return_shared(fund_balances);

//     };
//      ts::end(scenario_test);
// }

// #[test]
// #[expected_failure(abort_code =fp::ERROR_SHARE_ALREADY_CREATED)]

// fun admin_create_share_object() {

//    let owner: address = @0xA;
   
//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//       fp::init_for_testing(ts::ctx(scenario));
//    };
//    next_tx(scenario, owner);
//    {
//       create_share_objects<USDC>(scenario);
//    };
//    next_tx(scenario, owner);
//    {
//       create_share_objects<USDC>(scenario);
//    };

//    ts::end(scenario_test);
// }

// fun fund_distribution_test() {

//    let owner: address = @0xA;
//    let test_address1: address = @0xB;
//    let test_address2: address = @0xC;
//    let test_address3: address = @0xD;
//    let test_address4: address = @0xE;
   
//    let scenario_test = ts::begin(owner);
//    let scenario = &mut scenario_test;

//    // check init function
//    next_tx(scenario,owner);
//    {
//    fp::init_for_testing(ts::ctx(scenario));
//    init_for_testing_usdc(ts::ctx(scenario));
//    init_for_testing_usdt(ts::ctx(scenario));
//    };










//      ts::end(scenario_test);
// }



}