<template>
  <el-form
    :model="form"
    label-position="top"
    :rules="rules"
    ref="formRef"
    class="customer-form"
    size="default"
  >
    <el-form-item label="客户名称" prop="name">
      <el-input v-model="form.name" placeholder="公司或个人名称" />
    </el-form-item>
    <el-form-item label="发往地址">
      <el-input v-model="form.address" placeholder="收货地址" />
    </el-form-item>
    <div class="form-row">
      <el-form-item label="联系人" class="form-half">
        <el-input v-model="form.contact" placeholder="姓名" />
      </el-form-item>
      <el-form-item label="电话" class="form-half">
        <el-input v-model="form.phone" placeholder="手机号" />
      </el-form-item>
    </div>
  </el-form>
</template>

<script setup>
import { reactive, ref } from 'vue'

const form = reactive({
  name: '武汉锂鑫智造工程有限公司',
  address: '湖北省武汉市新洲区双柳街快云路1号',
  contact: '李长青',
  phone: '15002496736',
})

const rules = {
  name: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
}

const formRef = ref(null)

async function validate() {
  return formRef.value.validate()
}

function getData() {
  return { ...form }
}

defineExpose({ validate, getData })
</script>

<style scoped>
.customer-form .el-form-item {
  margin-bottom: 14px;
}

.customer-form .el-form-item:last-child {
  margin-bottom: 0;
}

.form-row {
  display: flex;
  gap: 12px;
}

.form-half {
  flex: 1;
}
</style>
