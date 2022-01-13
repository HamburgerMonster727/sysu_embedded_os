  /*�����嵥2.22�豸��д����ʵ�ַ�������*/                                                                            
                                                                                                   
 #include <linux/init.h>                                                                           
 #include <linux/module.h>                                                                         
 #include <linux/fs.h>                                                                             
 #include <linux/cdev.h>                                                                           
 #include <linux/device.h>                                                                         
 #include <asm/uaccess.h>      /* copy_to_user ... */                                               
                                                                                                   
 static int major;                                                                                  
 static int minor;                                                                                  
 struct cdev *char_cdev_rw;    /* cdev���ݽṹ*/                                                       
 static dev_t devno;           /* �豸���*/                                                           
 static struct class *char_cdev_rw_class;                                                          
 static char dev_rw_buff[64];  /* �豸�ڲ���д������*/                                                      
                                                                                                   
 #define DEVICE_NAME     "char_cdev_rw"                                                            
                                                                                                   
 static int char_cdev_rw_open(struct inode *inode, struct file *file )                             
 {                                                                                                 
 try_module_get(THIS_MODULE);                                                                      
 return 0;                                                                                         
 }                                                                                                 
                                                                                                   
 static int char_cdev_rw_release(struct inode *inode, struct file *file )                          
 {                                                                                                 
 module_put(THIS_MODULE);                                                                          
 return 0;                                                                                         
 }                                                                                                 
                                                                                                   
  static ssize_t char_cdev_rw_read(struct file *file, char *buf,size_t count, loff_t *f_pos)       
 {                                                                                                 
 	if (count > 64) {                                                                                 
 		printk("Max length is 64\n");                                                                     
 		count = 64;                                                                                       
 		}                                                                                                 
  
                                                                                                 
 if (copy_to_user((void *)buf, dev_rw_buff, count)) {                                              
 			printk("copy_to_user err\n");                                                                     
 			return -EFAULT;                                                                                   
      }                                                                                            
                                                                                                   
 return count;                                                                                     
 }                                                                                                 
                                                                                                   
 static ssize_t char_cdev_rw_write(struct file *file, const char *buf, size_t count, loff_t *f_pos)
 {                                                                                                 
 if (count > 64) {                                                                                 
 printk("Max length is 64\n");                                                                     
 count = 64;                                                                                       
 }                                                                                                 
                                                                                                   
 if (copy_from_user(&dev_rw_buff, buf, count) ) {                                                  
 printk("copy_from_user err\n");                                                                   
 return -EFAULT;                                                                                   
 }                                                                                                 
                                                                                                   
 return count;                                                                                     
 }                                                                                                 
                                                                                                   
 struct file_operations char_cdev_rw_fops = {                                                      
 .owner   = THIS_MODULE,                                                                           
 .read    = char_cdev_rw_read,                                                                     
 .write   = char_cdev_rw_write,                                                                    
 .open    = char_cdev_rw_open,                                                                     
 .release = char_cdev_rw_release,                                                                  
 };                                                                                                
                                                                                                   
 static int __init char_cdev_rw_init(void)                                                         
 {                                                                                                 
      int ret;                                                                                     
 int i;                                                                                            
                                                                                                   
      ret = alloc_chrdev_region(&devno, minor, 1, "char_cdev_rw");/* ��ϵͳ��ȡ���豸��*/                   
 major = MAJOR(devno);                                                                             
 if (ret < 0) {                                                                                    
 printk(KERN_ERR "cannot get major %d \n", major);                                                 
 return -1;                                                                                        
 }                                                                                                 
                                                                                                   
      char_cdev_rw = cdev_alloc();           /* ����char_cdev_rw�ṹ*/                                 
 if (char_cdev_rw != NULL) {                                                                       
          cdev_init(char_cdev_rw, &char_cdev_rw_fops);   /* ��ʼ��char_cdev_rw�ṹ*/                    
 char_cdev_rw->owner = THIS_MODULE;                                                                
          if(cdev_add(char_cdev_rw, devno, 1) != 0) {/* ����char_cdev_rw��ϵͳ��*/                       
 printk(KERN_ERR "add cdev error!\n");                                                             
 goto error;                                                                                       
 }                                                                                                 
 } else {                                                                                          
 printk(KERN_ERR "cdev_alloc error!\n");                                                           
 return -1;                                                                                        
 }                                                                                                 
                                                                                                   
 char_cdev_rw_class = class_create(THIS_MODULE, "char_cdev_rw_class");                             
 if (IS_ERR(char_cdev_rw_class)) {                                                                 
 printk(KERN_INFO "create class error\n");                                                         
 return -1;                                                                                        
 }                                                                                                 
                                                                                                   
 device_create(char_cdev_rw_class, NULL, devno, NULL, "char_cdev_rw");                             
                                                                                                   
 for (i=0; i<64; i++) {                                                                           
          dev_rw_buff[i] = i;     /* ��ʼ���豸�ڲ���д������*/                                               
 }                                                                                                
                                                                                                  
 return 0;                                                                                        
                                                                                                  
 error:                                                                                           
      unregister_chrdev_region(devno, 1);             /* �ͷ��Ѿ���õ��豸��*/                             
 return ret;                                                                                      
 }                                                                                                
                                                                                                  
 static void __exit char_cdev_rw_exit(void)                                                       
 {                                                                                                
      cdev_del(char_cdev_rw);                        /* �Ƴ��ַ��豸*/                                  
      unregister_chrdev_region(devno, 1);                 /* �ͷ��豸��*/                              
 device_destroy(char_cdev_rw_class, devno);                                                       
 class_destroy(char_cdev_rw_class);                                                               
 }                                                                                                
                                                                                                  
 module_init(char_cdev_rw_init);                                                                  
 module_exit(char_cdev_rw_exit);                                                                  
                                                                                                  
 MODULE_LICENSE("GPL");                                                                           
 MODULE_AUTHOR("Chenxibing, linux@zlgmcu.com");                                                   