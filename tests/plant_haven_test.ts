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
  }
});

Clarinet.test({
  name: "Ensure only owner can create challenges",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Owner creating challenge should succeed
      Tx.contractCall('plant-haven', 'create-challenge', [
        types.ascii("Summer Growing Challenge"),
        types.ascii("Grow the biggest tomato"),
        types.uint(100),
        types.uint(1000)
      ], deployer.address),
      
      // Non-owner creating challenge should fail
      Tx.contractCall('plant-haven', 'create-challenge', [
        types.ascii("Unauthorized Challenge"),
        types.ascii("Should fail"),
        types.uint(100),
        types.uint(1000)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectErr(types.uint(100)); // err-owner-only
  }
});