public with sharing class IntrestProductsController {

	public ClassIntrestProducts IntrestProducts{get;set;}

	public class ClassIntrestProducts{
		public Task task {
			get { return (task == null ? new Task() : task); }
			set;
		}
		public Boolean accFlag {
			get { return (accFlag == null ? false : accFlag); }
			set;
		}
		public Boolean oppFlag {
			get { return (oppFlag == null ? false : oppFlag); }
			set;
		}
		public String SelectedProduct		{get; set;}
		public List<Product2> AllProduct	{get; set;}

		public Integer CountOfAllProduct {
			get { return (AllProduct != null ? AllProduct.size() : 0); }
			set;
		}
		public List<IntrestProduct> IntrestProducts {
			get { return (IntrestProducts == null ? new List<IntrestProduct>() : IntrestProducts); }
			set;
		}
		public Integer CountOfIntrestProducts {
			get { return (IntrestProducts != null ? IntrestProducts.size() : 0); }
			set;
		}
		public List<SelectOption> ProductOptions {
			get { return (AllProduct != null && AllProduct.size() > 0 ? CreateProductOptions(AllProduct) : new List<SelectOption>()); }
			set;
		}

		public ClassIntrestProducts() {
		}
		
		public ClassIntrestProducts(String TaskID) {
			SelectTask(TaskID);
			Refresh();
		}
		
		public List<SelectOption> CreateProductOptions(List<Product2> products) {
			List<SelectOption> options = new List<SelectOption>();
			for (Product2 product : products ) {
				String ItemValue = (product.Id != null ? String.valueOf(product.Id) : '-');
				String ItemLabel = (product.Name != null ? product.Name : '-');
				options.add(new SelectOption(ItemValue , ItemLabel));
			}
			return options;
		}
		
		public void SelectTask(String TaskID) {
			try {
				task = [SELECT WhoId, WhatId, AccountId, Account.Id
				        FROM Task
				        WHERE Id = :TaskID
				        AND Account.IsDeleted = false];
			} catch (Exception ex) {
				task = new Task();
			}
			try {
				Account tempAccount = [SELECT Id FROM Account WHERE Id = :task.AccountId];
				accFlag = true;
			} catch (Exception ex){
				accFlag = false;
			}
			try {
				Opportunity tempopportunity = [SELECT Id FROM Opportunity WHERE Id = :task.WhatId];
				oppFlag = true;
			} catch (Exception ex){
				oppFlag = false;
			}
		}

		public void Refresh() {
			IntrestProducts = new List<IntrestProduct>();
			List<IntrestProduct__c> iProducts = new List<IntrestProduct__c>();
			if (task.Account.Id != null) iProducts = [SELECT Id, Name, CreatedDate, Account__c, Opportunity__c,
			                                          		Task__c, Product__c, Product__r.Id, Product__r.Name
			                                          FROM IntrestProduct__c 
			                                          WHERE Account__c = :task.Account.Id
			                                          AND IsDeleted = false
			                                          ORDER BY Product__r.Name];
			List<Id> ProductsId = new List<Id>();
			for (IntrestProduct__c product : iProducts) {
				ProductsId = addItem(product, ProductsId);
			}
			AllProduct = [SELECT Id, Name FROM Product2 WHERE Id NOT IN :ProductsId ORDER BY Name];
		}

		public List<Id> addItem(IntrestProduct__c product, List<Id> ProductsId) {
			if (ProductsId == null) ProductsId = new List<Id>();
			IntrestProducts.add(new IntrestProduct(product));
			if (product.Product__c != null) ProductsId.add(product.Product__c);
			return ProductsId;
		}

		public void AddIntrestProduct(){
			IntrestProduct__c ip = new IntrestProduct__c();
			if (task.id != null )			ip.Task__c = task.id;
			if (oppFlag )					ip.Opportunity__c = task.WhatId;
			if (accFlag )					ip.Account__c =task.Account.id;
			if (SelectedProduct != null )	ip.Product__c = SelectedProduct;
			if (SelectedProduct != null) 	try {insert ip;} catch (Exception ec) {}
		}
	}

	public class IntrestProduct{
		public IntrestProduct__c product {get; set;}
		
		public IntrestProduct(IntrestProduct__c product) {
			if (product != null) {
				this.product = product;
			} else {
				this.product = new IntrestProduct__c();
			}
		}
		
		public void Remove() {
			if (this.product.Id != null) try {delete this.product;} catch (Exception ex) {}
		}
	}

	public IntrestProductsController(ApexPages.StandardController stdController) {
		Id TaskID = stdController.getId();
		IntrestProducts = new ClassIntrestProducts(TaskID);
	}

	public IntrestProductsController() {
		String TaskID = '';
		if (ApexPages.currentPage().getParameters().get('id') != null) TaskID = ApexPages.currentPage().getParameters().get('id') ;
		IntrestProducts = new ClassIntrestProducts(TaskID);
	}

}