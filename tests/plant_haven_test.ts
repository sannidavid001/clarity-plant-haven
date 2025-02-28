import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure user can register",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('plant-haven', 'register-user', [
        types.ascii("plant_lover_1")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify user info
    let userInfo = chain.mineBlock([
      Tx.contractCall('plant-haven', 'get-user-info', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const userData = userInfo.receipts[0].result.expectSome();
    assertEquals(userData['username'], "plant_lover_1");
    assertEquals(userData['reputation'], types.uint(0));
    assertEquals(userData['expert-status'], false);
  }
});

Clarinet.test({
  name: "Ensure user can add plants",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('plant-haven', 'add-plant', [
        types.ascii("Monstera Deliciosa"),
        types.ascii("Beautiful swiss cheese plant"),
        types.ascii("Water weekly, indirect light")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify plant info
    let plantInfo = chain.mineBlock([
      Tx.contractCall('plant-haven', 'get-plant-info', [
        types.uint(0)
      ], wallet1.address)
    ]);
    
    const plantData = plantInfo.receipts[0].result.expectSome();
    assertEquals(plantData['name'], "Monstera Deliciosa");
    assertEquals(plantData['owner'], wallet1.address);
    assertEquals(plantData['listed-for-swap'], false);
  }
});

Clarinet.test({
  name: "Ensure plant swap creation works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // First add a plant
    let block = chain.mineBlock([
      Tx.contractCall('plant-haven', 'add-plant', [
        types.ascii("Monstera Deliciosa"),
        types.ascii("Beautiful swiss cheese plant"),
        types.ascii("Water weekly, indirect light")
      ], wallet1.address)
    ]);
    
    // Then create swap listing
    let swapBlock = chain.mineBlock([
      Tx.contractCall('plant-haven', 'create-swap-listing', [
        types.uint(0),
        types.ascii("Snake Plant")
      ], wallet1.address)
    ]);
    
    swapBlock.receipts[0].result.expectOk();
    
    // Verify plant is listed for swap
    let plantInfo = chain.mineBlock([
      Tx.contractCall('plant-haven', 'get-plant-info', [
        types.uint(0)
      ], wallet1.address)
    ]);
    
    const plantData = plantInfo.receipts[0].result.expectSome();
    assertEquals(plantData['listed-for-swap'], true);
  }
});
