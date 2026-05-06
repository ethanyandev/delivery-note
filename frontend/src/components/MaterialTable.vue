<template>
  <section class="table-wrap">
    <!-- Header -->
    <div class="table-header">
      <div class="table-title">
        <h3>物料清单</h3>
        <span class="badge" v-if="materials.length">{{ materials.length }}</span>
      </div>
      <div class="table-summary" v-if="selectedMaterials.length > 0">
        <span class="summary-selected">已选 {{ selectedMaterials.length }} 项</span>
        <span class="summary-divider"></span>
        <span class="summary-amount">¥{{ totalAmount.toFixed(2) }}</span>
      </div>
    </div>

    <!-- Table -->
    <div class="table-body" v-if="materials.length > 0">
      <el-table
        :data="materials"
        @selection-change="handleSelectionChange"
        ref="tableRef"
        stripe
        style="width: 100%"
        :header-cell-style="{ textAlign: 'center' }"
        :max-height="tableMaxHeight"
      >
        <el-table-column type="selection" width="40" fixed />
        <el-table-column prop="index" label="#" width="44" align="center">
          <template #default="{ row }">
            <span class="row-index">{{ row.index }}</span>
          </template>
        </el-table-column>
        <el-table-column label="物料" min-width="220">
          <template #default="{ row }">
            <div class="cell-material">
              <span class="material-name">{{ row.material_name }}</span>
              <span class="material-spec" v-if="row.spec">{{ row.spec }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="数量" width="110" align="center">
          <template #default="{ row }">
            <el-input-number
              v-model="row.quantity"
              :min="1"
              :precision="0"
              size="small"
              controls-position="right"
              class="qty-input"
            />
          </template>
        </el-table-column>
        <el-table-column prop="unit" label="单位" width="52" align="center">
          <template #default="{ row }">
            <span class="cell-unit">{{ row.unit }}</span>
          </template>
        </el-table-column>
        <el-table-column label="单价" width="80" align="right">
          <template #default="{ row }">
            <span class="cell-price">{{ row.unit_price }}</span>
          </template>
        </el-table-column>
        <el-table-column label="金额" width="100" align="right">
          <template #default="{ row }">
            <span class="cell-amount">{{ (row.unit_price * row.quantity).toFixed(2) }}</span>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- Empty state -->
    <div class="empty" v-else>
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" class="empty-icon">
        <rect x="2" y="3" width="20" height="18" rx="2" ry="2"/>
        <line x1="8" y1="10" x2="16" y2="10"/>
        <line x1="8" y1="14" x2="12" y2="14"/>
      </svg>
      <p class="empty-title">暂无物料数据</p>
      <p class="empty-desc">请在左侧上传物料采购清单</p>
    </div>
  </section>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  materials: { type: Array, default: () => [] },
})

const emit = defineEmits(['selection-change'])

const tableRef = ref(null)
const selectedMaterials = ref([])
const tableMaxHeight = ref(600)

const totalAmount = computed(() =>
  selectedMaterials.value.reduce((s, i) => s + i.unit_price * i.quantity, 0)
)

function handleSelectionChange(selection) {
  selectedMaterials.value = selection
  emit('selection-change', selection.length)
}

function getSelectedMaterials() {
  return selectedMaterials.value.map((item) => ({
    material_name: item.material_name,
    spec: item.spec,
    quantity: item.quantity,
    unit: item.unit,
    unit_price: item.unit_price,
    remark: item.remark,
  }))
}

function updateTableHeight() {
  tableMaxHeight.value = window.innerHeight - 180
}

onMounted(() => {
  updateTableHeight()
  window.addEventListener('resize', updateTableHeight)
})

onUnmounted(() => {
  window.removeEventListener('resize', updateTableHeight)
})

defineExpose({ getSelectedMaterials })
</script>

<style scoped>
.table-wrap {
  background: var(--color-white);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--color-border);
}

.table-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-title h3 {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.badge {
  background: var(--color-primary-bg);
  color: var(--color-primary);
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 10px;
}

.table-summary {
  display: flex;
  align-items: center;
  gap: 12px;
}

.summary-selected {
  font-size: 13px;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.summary-divider {
  width: 1px;
  height: 14px;
  background: var(--color-border);
}

.summary-amount {
  font-size: 18px;
  font-weight: 700;
  color: var(--color-primary);
  font-variant-numeric: tabular-nums;
}

/* Table body */
.table-body {
  flex: 1;
}

.row-index {
  color: var(--color-text-muted);
  font-size: 12px;
  font-variant-numeric: tabular-nums;
}

.cell-material {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 4px 0;
}

.material-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--color-text);
  line-height: 1.4;
}

.material-spec {
  font-size: 12px;
  color: var(--color-text-muted);
  line-height: 1.3;
}

.qty-input {
  width: 86px !important;
}

.cell-unit {
  font-size: 12px;
  color: var(--color-text-muted);
}

.cell-price {
  font-size: 13px;
  color: var(--color-text-secondary);
  font-variant-numeric: tabular-nums;
}

.cell-amount {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
  font-variant-numeric: tabular-nums;
}

/* Empty */
.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  gap: 8px;
}

.empty-icon {
  color: var(--color-border);
  margin-bottom: 8px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.empty-desc {
  font-size: 13px;
  color: var(--color-text-muted);
}
</style>
