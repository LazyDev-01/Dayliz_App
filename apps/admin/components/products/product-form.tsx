import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import Image from "next/image"
import { Loader2, Upload } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { useToast } from "@/components/ui/use-toast"
import { Card, CardContent } from "@/components/ui/card"
import { Category, Product, Subcategory } from "@/types"
import { logAdminAction } from "@/lib/admin-logs"
import { createProduct, updateProduct, uploadProductImage } from "@/lib/api"

// Form schema
const productSchema = z.object({
  name: z.string().min(1, "Product name is required"),
  description: z.string().min(1, "Description is required"),
  price: z.coerce.number().positive("Price must be positive"),
  category_id: z.string().min(1, "Category is required"),
  subcategory_id: z.string().nullable().optional(),
  in_stock: z.boolean().default(true),
})

type ProductFormValues = z.infer<typeof productSchema> & {
  image?: File | null;
}

interface ProductFormProps {
  product?: Product;
  isEditing?: boolean;
}

export function ProductForm({ product, isEditing = false }: ProductFormProps) {
  const [categories, setCategories] = useState<Category[]>([])
  const [subcategories, setSubcategories] = useState<Subcategory[]>([])
  const [filteredSubcategories, setFilteredSubcategories] = useState<Subcategory[]>([])
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [imagePreview, setImagePreview] = useState<string | null>(product?.image_url || null)
  const [imageFile, setImageFile] = useState<File | null>(null)
  
  const router = useRouter()
  const supabase = createClientComponentClient()
  const { toast } = useToast()

  // Initialize form with existing product data or defaults
  const form = useForm<ProductFormValues>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      name: product?.name || "",
      description: product?.description || "",
      price: product?.price || 0,
      category_id: product?.category_id || "",
      subcategory_id: product?.subcategory_id || null,
      in_stock: product?.in_stock ?? true,
    },
  })

  // Fetch categories and subcategories
  useEffect(() => {
    const fetchCategoriesAndSubcategories = async () => {
      try {
        // Fetch categories
        const { data: categoriesData, error: categoriesError } = await supabase
          .from('categories')
          .select('*')
          .order('name');
        
        if (categoriesError) throw categoriesError;
        setCategories(categoriesData || []);
        
        // Fetch subcategories
        const { data: subcategoriesData, error: subcategoriesError } = await supabase
          .from('subcategories')
          .select('*')
          .order('name');
        
        if (subcategoriesError) throw subcategoriesError;
        setSubcategories(subcategoriesData || []);
        
        // If editing, filter subcategories for the selected category
        if (isEditing && product?.category_id) {
          const filtered = subcategoriesData?.filter(
            sub => sub.category_id === product.category_id
          ) || [];
          setFilteredSubcategories(filtered);
        }
      } catch (error) {
        console.error('Error fetching categories:', error);
        toast({
          title: "Error",
          description: "Failed to load categories",
          variant: "destructive",
        });
      }
    };
    
    fetchCategoriesAndSubcategories();
  }, [supabase, isEditing, product, toast]);

  // Update subcategories when category changes
  const handleCategoryChange = (categoryId: string) => {
    const filtered = subcategories.filter(sub => sub.category_id === categoryId);
    setFilteredSubcategories(filtered);
    
    // Reset subcategory selection if the current selection doesn't belong to the new category
    const currentSubcategoryId = form.getValues("subcategory_id");
    if (currentSubcategoryId) {
      const belongsToNewCategory = filtered.some(sub => sub.id === currentSubcategoryId);
      if (!belongsToNewCategory) {
        form.setValue("subcategory_id", null);
      }
    }
  };

  // Handle image upload
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const previewUrl = URL.createObjectURL(file);
      setImagePreview(previewUrl);
    }
  };

  // Form submission
  const onSubmit = async (values: ProductFormValues) => {
    try {
      setIsSubmitting(true);
      
      // Get current user for logging
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("User not authenticated");
      
      let imageUrl = product?.image_url || "";
      
      // Upload image if provided
      if (imageFile) {
        imageUrl = await uploadProductImage(imageFile);
      }
      
      if (isEditing && product) {
        // Update existing product
        const updatedProduct = await updateProduct(product.id, {
          ...values,
          image_url: imageUrl,
        });
        
        // Log admin action
        await logAdminAction(
          user.id,
          'update',
          'product',
          product.id,
          { productName: values.name }
        );
        
        toast({
          title: "Product updated",
          description: `${values.name} has been updated successfully`,
        });
      } else {
        // Create new product
        const newProduct = await createProduct({
          ...values,
          image_url: imageUrl,
        });
        
        // Log admin action
        await logAdminAction(
          user.id,
          'create',
          'product',
          newProduct.id,
          { productName: values.name }
        );
        
        toast({
          title: "Product created",
          description: `${values.name} has been added to your catalog`,
        });
      }
      
      // Redirect back to products page
      router.push('/products');
      router.refresh();
      
    } catch (error) {
      console.error('Error saving product:', error);
      toast({
        title: "Error",
        description: `Failed to ${isEditing ? 'update' : 'create'} product`,
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-6">
            {/* Product Name */}
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Product Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter product name" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            {/* Product Description */}
            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Enter product description" 
                      className="min-h-[120px]" 
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            {/* Price */}
            <FormField
              control={form.control}
              name="price"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Price (₹)</FormLabel>
                  <FormControl>
                    <Input 
                      type="number" 
                      step="0.01" 
                      min="0"
                      placeholder="0.00" 
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            {/* Category */}
            <FormField
              control={form.control}
              name="category_id"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Category</FormLabel>
                  <Select 
                    onValueChange={(value) => {
                      field.onChange(value);
                      handleCategoryChange(value);
                    }}
                    defaultValue={field.value}
                  >
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select a category" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {categories.map((category) => (
                        <SelectItem key={category.id} value={category.id}>
                          {category.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            {/* Subcategory */}
            <FormField
              control={form.control}
              name="subcategory_id"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Subcategory (Optional)</FormLabel>
                  <Select 
                    onValueChange={field.onChange}
                    defaultValue={field.value || undefined}
                  >
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select a subcategory" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {filteredSubcategories.map((subcategory) => (
                        <SelectItem key={subcategory.id} value={subcategory.id}>
                          {subcategory.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormDescription>
                    First select a category to see available subcategories
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            {/* In Stock */}
            <FormField
              control={form.control}
              name="in_stock"
              render={({ field }) => (
                <FormItem className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-4">
                  <FormControl>
                    <Checkbox
                      checked={field.value}
                      onCheckedChange={field.onChange}
                    />
                  </FormControl>
                  <div className="space-y-1 leading-none">
                    <FormLabel>In Stock</FormLabel>
                    <FormDescription>
                      This product is currently available for purchase
                    </FormDescription>
                  </div>
                </FormItem>
              )}
            />
          </div>
          
          {/* Image Upload */}
          <div>
            <Card>
              <CardContent className="pt-6">
                <div className="space-y-4">
                  <div>
                    <FormLabel>Product Image</FormLabel>
                    <FormDescription className="mb-2">
                      Upload a high-quality image of your product
                    </FormDescription>
                  </div>
                  
                  {/* Image Preview */}
                  <div className="border rounded-md overflow-hidden aspect-square w-full relative bg-muted">
                    {imagePreview ? (
                      <Image
                        src={imagePreview}
                        alt="Product preview"
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="flex items-center justify-center h-full text-muted-foreground">
                        No image
                      </div>
                    )}
                  </div>
                  
                  {/* Image Upload Input */}
                  <div className="flex justify-center">
                    <label htmlFor="image-upload" className="cursor-pointer">
                      <div className="flex items-center gap-2 bg-muted hover:bg-muted/80 text-muted-foreground px-4 py-2 rounded-md">
                        <Upload className="h-4 w-4" />
                        <span>{imagePreview ? "Change Image" : "Upload Image"}</span>
                      </div>
                      <input
                        id="image-upload"
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={handleImageChange}
                      />
                    </label>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
        
        {/* Form Actions */}
        <div className="flex justify-end gap-4">
          <Button
            type="button"
            variant="outline"
            onClick={() => router.back()}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {isEditing ? "Update Product" : "Create Product"}
          </Button>
        </div>
      </form>
    </Form>
  );
} 