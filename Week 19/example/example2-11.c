  /*�����嵥2-11*/                                                           
 #include <linux/init.h>                                               
 #include <linux/module.h>                                             
 #include <linux/fs.h>                                               
                                                                      
  #define DEVICE_NAME   "char_null"                                   
  static int major = 232;/* �������豸�ŵ�ȫ�ֱ���*/                             
                                                                      
  static int __init char_null_init(void)                              
  {                                                                   
      int ret;                                                       
                                                                     
      ret = register_chrdev(major, DEVICE_NAME, &major);/* �����豸�ź�ע��*/
      if (major > 0) { /* ��̬�豸��*/                                    
          if (ret < 0) {                                             
              printk(KERN_INFO " Can't get major number!\n");        
              return ret;                                            
          }                                                          
      } else { /* ��̬�豸��*/                                            
          printk(KERN_INFO " ret is %d\n", ret);                     
          major = ret;  /* ���涯̬��ȡ�������豸��*/                            
      }                                                              
      printk(KERN_INFO "%s ok!\n", __func__);                        
      return ret;                                                    
  }                                                                  
                                                                     
  static void __exit char_null_exit(void)                            
  {                                                                  
      unregister_chrdev(major, DEVICE_NAME);                         
      printk(KERN_INFO "%s\n", __func__);                            
  }                                                                  
                                                                     
  module_init(char_null_init);                                       
  module_exit(char_null_exit);                                       
                                                                     
  MODULE_LICENSE("GPL");                                             
  MODULE_AUTHOR("Chenxibing, linux@zlgmcu.com");                     