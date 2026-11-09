<?php

namespace App\Filament\Resources\Products\Pages;

use App\Filament\Resources\Products\ProductResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditProduct extends EditRecord
{
    protected static string $resource = ProductResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()
                ->before(function (DeleteAction $action) {
                    $record = $this->getRecord();
                    if ($record->orderItems()->whereHas('order', function ($query) {
                        $query->whereNotIn('status', ['selesai', 'dibatalkan']);
                    })->exists()) {
                        \Filament\Notifications\Notification::make()
                            ->title('Gagal Menghapus')
                            ->body("Produk '{$record->nama}' masih terpakai pada pesanan aktif.")
                            ->danger()
                            ->send();

                        $action->halt();
                    }

                    if ($record->orderItems()->exists()) {
                        \Filament\Notifications\Notification::make()
                            ->title('Gagal Menghapus')
                            ->body("Produk '{$record->nama}' tidak dapat dihapus karena memiliki riwayat transaksi pesanan.")
                            ->danger()
                            ->send();

                        $action->halt();
                    }
                }),
        ];
    }
}
